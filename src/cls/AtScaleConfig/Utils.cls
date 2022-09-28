/// The silly name is because it would otherwise map itself out of reach!
Class AtScaleConfig.Utils
{

/// <p>This function creates a new database to use for storing Adaptive Analytics aggregate data,
/// pre-calculated by Adaptive Analytics to serve queries faster based on analysis of the source 
/// schema and current workload. This data is managed entirely by Adaptive Analytics, and this script
/// only ensures that data is physically located in a database that's separate from the default database
/// for the current namespace. It implements several InterSystems IRIS best practices appropriate for 
/// this kind of transient data, such as disabling journaling.</p>
/// <p>This script is provided for demonstration purposes and serves a typical deployment scenario. For
/// more comprehensive documentation on the steps to manage every detail of your IRIS environment, please
/// refer to the product documentation.</p>
/// <p>After this script has been run, all tables in the <var>package</var> schema will have their
/// definitions and data mapped to the newly created database (Adaptive Analytics by default puts
/// these tables in a package named "AtScale"). Tables in subpackages are excluded, as 
/// are tables in the designated package that aren't using extent sets (dwelling outside
/// the defaults for DDL-created tables). This schema will also be configured to skip locking and
/// enable parallel DML operations to speed up aggregate builds.</p>
/// <p>To run the script, make sure you are logged on with an appropriately privileged user (we're
/// creating a database!) and provide a filesystem location where the database should be created, such 
/// as /usr/irissys/mgr/aggregates, and the name of the "aggregate schema" you specified in the 
/// warehouse setup screen.</p>
/// <example>write ##class(AtScaleConfig.Utils).CreateDatabase("/usr/irissys/mgr/aggregates")</example>
ClassMethod CreateDatabase(location As %String, package As %String = "AtScale", verbose As %Boolean = 1) As %Status [ SqlName = CreateDatabase, SqlProc ]
{
    set sc = $$$OK, namespace = $namespace
    try {
        if ($$$LOWER(package) = "atscaleconfig") {
            write:verbose !,"Cannot map the 'AtScaleConfig' package using this script, as it would render this class inaccessible"
            set sc = $$$ERROR($$$GeneralError,"Invalid package name: '"_package_"'")
            quit
        }

        write:verbose !,"Switching to %SYS"
        zn "%SYS"

        // make sure location exists
        set dir = ##class(%File).%New()
        if '##class(%File).Exists(location) {
            if '##class(%File).CreateDirectoryChain(location, .error) {
                set sc = $$$ERROR($$$GeneralError, "Failed to create directory '"_location_"' - error code "_error)
                quit
            }
        }

        // we'll name the database after the package we're mapping
        set dbname = package

        // check if database already exists
        if ##class(Config.Databases).Exists(dbname, .cfg) {
            if cfg.Directory '= location {
                set sc = $$$ERROR($$$GeneralError, "Database '"_dbname_"' already existed at a different location: "_cfg.Directory)
                quit
            }
            write:verbose !,"Database '"_dbname_"' already exists"
        } else {

            if ##class(SYS.Database).%ExistsId(location) {
                write:verbose !,"Reusing existing database at ",location
                set db = ##class(SYS.Database).%OpenId(location)
            } else {
                write:verbose !,"Creating database at ",location
                set db = ##class(SYS.Database).%New()
                set db.Directory = location
            }
            set db.GlobalJournalState = 2  // disable journaling
            set sc = db.%Save()
            quit:$$$ISERR(sc)

            // now register the database at the specified location
            kill properties
            set properties("Directory") = location
            set sc = ##class(Config.Databases).Create(dbname, .properties)
            quit:$$$ISERR(sc)
        }

        // create a package mapping from <package> to the new database
        kill cfg
        if ##class(Config.MapPackages).Exists(namespace, package, .cfg) {
            write:verbose !,"Package mapping already exists, mapped to ",cfg.Database
        } else {
            write:verbose !,"Creating package mapping for ",package
            kill properties
            set properties("Database") = dbname
            set sc = ##class(Config.MapPackages).Create(namespace, package, .properties)
            quit:$$$ISERR(sc)
        }

        // create a global mapping for all USEEXTENTSET=1 table data to the new database
        kill cfg
        set globalprefix = ..GetGlobalPrefix(package)
        if ##class(Config.MapGlobals).Exists(namespace, globalprefix, .cfg) {
            write:verbose !,"Global mapping already exists, mapped to ",cfg.Database
        } else {
            write:verbose !,"Creating global mapping for ",globalprefix
            kill properties
            set properties("Database") = dbname
            set sc = ##class(Config.MapGlobals).Create(namespace, globalprefix, .properties)
            quit:$$$ISERR(sc)
        }

        // set schema-wide flags
        zn namespace
        write:verbose !,"Configuring schema-wide flags"
        set schemaName = $SYSTEM.SQL.Schema.GetSchemaFromPackage(package)
        set ^rINDEXSQL("schema",$$$UPPER(schemaName),"settings","DML_NOLOCK") = 1
        set ^rINDEXSQL("schema",$$$UPPER(schemaName),"settings","DML_PARALLEL") = 1

    } catch (ex) {
        set sc = ex.AsStatus()
    }
    zn namespace
    if verbose {
        if $$$ISERR(sc) {
            write !,"Unexpected error: ",!
            do $system.OBJ.DisplayError(sc)
        }
        write !
    }
    quit sc
}

/// This method drops the mappings created in the <method>CreateDatabase</method> script.
ClassMethod DropMappings(package As %String = "AtScale", verbose As %Boolean = 1) As %Status [ SqlName = DropMappings, SqlProc ]
{
    set namespace = $NAMESPACE
    try {
        zn "%SYS"
        set globalprefix = ..GetGlobalPrefix(package)
        write:verbose !,"Dropping global mapping ",globalprefix
        set sc = ##class(Config.MapGlobals).Delete(namespace, globalprefix)
        quit:$$$ISERR(sc)

        write:verbose !,"Dropping package mapping ",package
        set sc = ##class(Config.MapPackages).Delete(namespace, package)
        quit:$$$ISERR(sc)

    } catch (ex) {
        set sc = ex.AsStatus()
    }
    zn namespace
    if verbose {
        if $$$ISERR(sc) {
            write !,"Unexpected error: ",!
            do $system.OBJ.DisplayError(sc)
        }
        write !
    }
    zn namespace
    quit sc
}

/// Utility function to retrieve the package portion of USEEXTENTSET=1 globals for the given package
ClassMethod GetGlobalPrefix(package As %String) As %String [ Internal, Private ]
{
    quit $e($p($$generateExtentGlobal^%occStorageUtil(package_".dummy"),".",1),2,*)_".*"
}

/// Stored procedure returning table column statistics, gathering them on the fly if this 
/// table doesn't have any yet.
Query GetTableStats(tableName As %String) As %Query(ROWSPEC = "COLUMN_NUMBER:%Integer,FIELD_NAME:%String,DATATYPE:%String,REQUIRED:%String,HIDDEN:%String,MAXLEN:%String,MINVAL:%String,MAXVAL:%String,SELECTIVITY:%String,OUTLIER_SELECTIVITY:%String,OUTLIER_VALUE:%String,AVERAGE_FIELD_SIZE:%Numeric") [ SqlName = GetTableStats, SqlProc ]
{
}

ClassMethod GetTableStatsExecute(ByRef qHandle As %Binary, tableName As %String) As %Status [ Internal, ServerOnly = 1 ]
{
	kill qHandle
	set sc = $$$OK, qHandle = 0
	try {

        if '$system.SQL.Schema.TableExists(tableName, .metadata) {
			set sc = $$$ERROR($$$TableDoesNotExist, tableName)
			quit
		}
        set $lb(packageName, justTheTableName, className) = metadata
        set storageName = className _"||"_ ##class(%Dictionary.CompiledClass).%OpenId(className).StorageStrategy 
            
        set hasStats = $case(##class(%SQL.Manager.Catalog).GetCurrentTableExtentSize(packageName, justTheTableName),"":0, 100000:0, :1)

        // if ExtentSize was not set, check if there are custom selectivity settings
        if 'hasStats {
            set storageName = className _"||"_ ##class(%Dictionary.CompiledClass).%OpenId(className).StorageStrategy 
            &SQL(SELECT COUNT(*) INTO :hasStats FROM %Dictionary.CompiledStorageProperty WHERE parent = :storageName)
        } 
        do:'hasStats ##class(%SQL.Statement).%ExecDirect(,"TUNE TABLE "_tableName)
        
        set rs = ##class(%SQL.Statement).%ExecDirect(,"SELECT f.*, p.Name AS PROPERTY_NAME FROM %SQL_Manager.Fields(?,?) f LEFT JOIN %Dictionary.CompiledProperty p ON f.FIELD_NAME = p.SqlFieldName WHERE p.parent = ?", packageName, justTheTableName, className)
        while rs.%Next() {
            set prop = rs.%Get("PROPERTY_NAME")
            &SQL(SELECT COUNT(*) INTO :cdm FROM %Dictionary.CompiledStorageData WHERE parent = :storageName AND Attribute = :prop AND Structure = 'vector')
            set storageType = $s(cdm:"columnar", 1:"row")
            set qHandle = qHandle+1,
                qHandle(qHandle) = $lb(+rs.%Get("COLUMN_NUMBER"),rs.%Get("FIELD_NAME"),rs.%Get("DATATYPE"),storageType,rs.%Get("REQUIRED"),rs.%Get("HIDDEN"),rs.%Get("MAXLEN"),rs.%Get("MINVAL"),rs.%Get("MAXVAL"),rs.%Get("SELECTIVITY"),rs.%Get("OUTLIER_SELECTIVITY"),rs.%Get("OUTLIER_VALUE"),+rs.%Get("AVERAGE_FIELD_SIZE"))
        }
        
    } catch (ex) {
        set sc = ex.AsStatus()
    }
    set qHandle = 0
    quit sc
}

ClassMethod GetTableStatsFetch(ByRef qHandle As %Binary, Output Row As %List, Output AtEnd As %Boolean) As %Status [ Internal, ServerOnly = 1 ]
{
	set qHandle = $order(qHandle(qHandle),1,data)
	if qHandle="" {
		set AtEnd = 1, Row = ""
	} else {
		set AtEnd = 0, Row = data
	}
	quit $$$OK
}

ClassMethod GetTableStatsClose(ByRef qHandle As %Binary) As %Status [ Internal, ServerOnly = 1 ]
{
	kill qHandle
	quit $$$OK
}

}
