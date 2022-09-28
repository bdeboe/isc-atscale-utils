Include HLL

/// <p>This class contains a few utility methods for setting up your Adaptive Analytics environment.
/// The <method>Register</method> is a crucial part of initializing your Namespace for use with
/// Adaptive Analytics, as it ensures all functions are available in the system's current default
/// schema:</p>
/// <example>do ##class(AtScaleUDAF.Utils).Register()</example>
Class AtScaleUDAF.Utils
{

/// <p>This method creates the HyperLogLog and Quantile User-Defined Aggregate Functions in the 
/// system's current default schema, so they can be invoked directly in SQL statements without 
/// specifying a schema name. It also registers a few additional helper methods.</p>
/// <p>This function can be invoked through ObjectScript:</p>
/// <example>do ##class(AtScaleUDAF.Utils).Register()</example>
/// or SQL:
/// <example language="SQL">CALL AtScaleUDAF.Register()</example>
/// <p>Use <method>Unregister<method> in case you want to remove these functions from the current
/// schema.</p>
ClassMethod Register() As %Status [ SqlName = Register, SqlProc ]
{
    kill ddl
    set ddl = 5
    set ddl(1) = "CREATE OR REPLACE AGGREGATE HLL_estimate(value sql_variant) RETURNS BIGINT "
    set ddl(2) = "    INITIALIZE WITH AtScaleUDAF.HLL_Initialize "
    set ddl(3) = "    ITERATE WITH AtScaleUDAF.HLL_Update "
    set ddl(4) = "  " //  MERGE WITH AtScaleUDAF.HLL_MergeState "
    set ddl(5) = "    FINALIZE WITH AtScaleUDAF.HLL_Estimate"
    do RunDDL("HLL_estimate",.ddl)

    kill ddl
    set ddl = 5
    set ddl(1) = "CREATE OR REPLACE AGGREGATE HLL_aggregate_estimate(value VARCHAR) RETURNS BIGINT "
    set ddl(2) = "    INITIALIZE WITH AtScaleUDAF.HLL_Initialize "
    set ddl(3) = "    ITERATE WITH AtScaleUDAF.HLL_MergeSketch "
    set ddl(4) = "  " //  MERGE WITH AtScaleUDAF.HLL_MergeState "
    set ddl(5) = "    FINALIZE WITH AtScaleUDAF.HLL_Estimate"
    do RunDDL("HLL_aggregate_estimate",.ddl)
    
    kill ddl
    set ddl = 5
    set ddl(1) = "CREATE OR REPLACE AGGREGATE HLL_aggregate(value SQL_VARIANT) RETURNS VARCHAR(3200) "
    set ddl(2) = "    INITIALIZE WITH AtScaleUDAF.HLL_Initialize "
    set ddl(3) = "    ITERATE WITH AtScaleUDAF.HLL_Update "
    set ddl(4) = " " //   MERGE WITH AtScaleUDAF.HLL_MergeState "
    set ddl(5) = "    FINALIZE WITH AtScaleUDAF.HLL_Finalize"
    do RunDDL("HLL_aggregate",.ddl)
    
    kill ddl
    set ddl = 5
    set ddl(1) = "CREATE OR REPLACE AGGREGATE HLL_aggregate_merge(value VARCHAR) RETURNS VARCHAR(3200) "
    set ddl(2) = "    INITIALIZE WITH AtScaleUDAF.HLL_Initialize "
    set ddl(3) = "    ITERATE WITH AtScaleUDAF.HLL_MergeSketch "
    set ddl(4) = " " //   MERGE WITH AtScaleUDAF.HLL_MergeState "
    set ddl(5) = "    FINALIZE WITH AtScaleUDAF.HLL_Finalize"
    do RunDDL("HLL_aggregate_merge",.ddl)

    kill ddl
    set ddl = 5
    set ddl(1) = "CREATE OR REPLACE AGGREGATE quantile_sketch_merge(state VARCHAR) RETURNS VARCHAR(3200) "
    set ddl(2) = "    INITIALIZE WITH ATSCALEUDAF.QuantileMergeUDA_Initialize "
    set ddl(3) = "    ITERATE WITH ATSCALEUDAF.QuantileMergeUDA_Iterate "
    set ddl(4) = " " //   MERGE WITH ATSCALEUDAF.QuantileMergeUDA_Merge "
    set ddl(5) = "    FINALIZE WITH ATSCALEUDAF.QuantileMergeUDA_Estimate"
    do RunDDL("quantile_sketch_merge",.ddl)

    kill ddl
    set ddl = 5
    set ddl(1) = "CREATE OR REPLACE AGGREGATE quantile_estimate(value DOUBLE, quantile DOUBLE, compression INTEGER) RETURNS DOUBLE "
    set ddl(2) = "    INITIALIZE WITH ATSCALEUDAF.QuantileEstimateUDA_Initialize "
    set ddl(3) = "    ITERATE WITH ATSCALEUDAF.QuantileEstimateUDA_Iterate "
    set ddl(4) = " " //   MERGE WITH ATSCALEUDAF.QuantileEstimateUDA_Merge "
    set ddl(5) = "    FINALIZE WITH ATSCALEUDAF.QuantileEstimateUDA_Estimate"
    do RunDDL("quantile_estimate",.ddl)

    kill ddl
    set ddl = 5
    set ddl(1) = "CREATE OR REPLACE AGGREGATE quantile_sketch(value DOUBLE, compression INTEGER) RETURNS VARCHAR(3200) "
    set ddl(2) = "    INITIALIZE WITH ATSCALEUDAF.QuantileAggregateUDA_Initialize "
    set ddl(3) = "    ITERATE WITH ATSCALEUDAF.QuantileAggregateUDA_Iterate "
    set ddl(4) = " " //   MERGE WITH ATSCALEUDAF.QuantileAggregateUDA_Merge "
    set ddl(5) = "    FINALIZE WITH ATSCALEUDAF.QuantileAggregateUDA_Finalize"
    do RunDDL("quantile_sketch",.ddl)

    kill ddl
    set ddl = 2
    set ddl(1) = "CREATE FUNCTION quantilefromsketch(sketch VARCHAR, quantile DOUBLE) RETURNS DOUBLE "
    set ddl(2) = "    PROCEDURE LANGUAGE OBJECTSCRIPT { quit ##class(AtScaleUDAF.QuantileEstimateFromSketchUDF).evaluate(sketch, quantile)}"
    do RunDDL("quantilefromsketch",.ddl)

    kill ddl
    set ddl = 2
    set ddl(1) = "CREATE FUNCTION ATSCALE_HONEYBEE_VERSION() RETURNS VARCHAR "
    set ddl(2) = "    PROCEDURE LANGUAGE OBJECTSCRIPT { quit ##class(AtScaleUDAF.HoneyBeeVersionUDF).AtscaleHoneybeeVersion()}"
    do RunDDL("ATSCALE_HONEYBEE_VERSION",.ddl)
   
    quit $$$OK
    
RunDDL(name, &ddl) 
    set rs = ##class(%SQL.Statement).%ExecDirect(,.ddl)
    if rs.%SQLCODE'=0 {
        write !,"Error creating UDAF ",name,": ",rs.%Message
    } else {
        write !,"Created UDAF ",name," successfully"
    }
}

/// <p>In the event you need to remove the UDF and UDAF definitions created by 
/// <method>Register</method> from the default schema in the current namespace, 
/// this can be achieved using the <method>Unregister</method> function in
/// ObjectScript:</p>
/// <example>do ##class(AtScaleUDAF.Utils).Unregister()</example>
/// or SQL:
/// <example language="SQL">CALL AtScaleUDAF.Unregister()</example>
/// <p>Note that this method only removes the entry points. It does not drop the corresponding
/// code from the <package>AtScaleUDAF</package>, <package>HLL</package> and
/// <package>QUANTILE</package> packages.</p>
ClassMethod Unregister() As %Status [ SqlName = Unregister, SqlProc ]
{
    do ##class(%SQL.Statement).%ExecDirect(,"DROP AGGREGATE HLL_estimate")
    do ##class(%SQL.Statement).%ExecDirect(,"DROP AGGREGATE HLL_aggregate_estimate")
    do ##class(%SQL.Statement).%ExecDirect(,"DROP AGGREGATE HLL_aggregate")
    do ##class(%SQL.Statement).%ExecDirect(,"DROP AGGREGATE HLL_aggregate_merge")
    do ##class(%SQL.Statement).%ExecDirect(,"DROP AGGREGATE quantile_sketch_merge")
    do ##class(%SQL.Statement).%ExecDirect(,"DROP AGGREGATE quantile_estimate")
    do ##class(%SQL.Statement).%ExecDirect(,"DROP AGGREGATE quantile_sketch")
    do ##class(%SQL.Statement).%ExecDirect(,"DROP FUNCTION quantilefromsketch")
    do ##class(%SQL.Statement).%ExecDirect(,"DROP FUNCTION ATSCALE_HONEYBEE_VERSION")
    quit $$$OK
}

// Utility method returning the HLL Prefix

ClassMethod HLLPrefix() As %String [ Internal ]
{
    Return "_atscale_v"_##class(AtScaleUDAF.HoneyBeeVersionUDF).AtscaleHoneybeeVersion() _":"_"d14_"
}

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
/// <example>write ##class(AtScaleUDAF.Utils).CreateDatabase("/usr/irissys/mgr/aggregates")</example>
ClassMethod CreateDatabase(location As %String, package As %String = "AtScale", verbose As %Boolean = 1) As %Status [ SqlName = CreateDatabase, SqlProc ]
{
    set sc = $$$OK, namespace = $namespace
    try {
        if ($$$LOWER(package) = "atscaleudaf") {
            write:verbose !,"Cannot map the 'AtScaleUDAF' package using this script, as it would render this class inaccessible"
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

        set hasStats = $case(##class(%SQL.Manager.Catalog).GetCurrentTableExtentSize(packageName, justTheTableName),"":0, 100000:0, :1)

        // if ExtentSize was not set, check if there are custom selectivity settings
        if 'hasStats {
            set storageName = className _"||"_ ##class(%Dictionary.CompiledClass).%OpenId(className).StorageStrategy 
            &SQL(SELECT COUNT(*) INTO :hasStats FROM %Dictionary.CompiledStorageProperty WHERE parent = :storageName)
        } 
        do:'hasStats ##class(%SQL.Statement).%ExecDirect(,"TUNE TABLE "_tableName)
        
        set rs = ##class(%SQL.Statement).%ExecDirect(,"SELECT * FROM %SQL_Manager.Fields(?,?)", $lg(metadata,1), $lg(metadata,2))
        while rs.%Next() {
            set qHandle = qHandle+1,
                qHandle(qHandle) = $lb(+rs.%Get("COLUMN_NUMBER"),rs.%Get("FIELD_NAME"),rs.%Get("DATATYPE"),rs.%Get("REQUIRED"),rs.%Get("HIDDEN"),rs.%Get("MAXLEN"),rs.%Get("MINVAL"),rs.%Get("MAXVAL"),rs.%Get("SELECTIVITY"),rs.%Get("OUTLIER_SELECTIVITY"),rs.%Get("OUTLIER_VALUE"),+rs.%Get("AVERAGE_FIELD_SIZE"))
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
