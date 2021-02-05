/// The silly name is because it would otherwise map itself out of reach!
Class AtScaleConfig.Utils
{

/// <p>Creates a new database to use for storing AtScale aggregates, implementing
/// InterSystems IRIS best practices.</p>
/// <p>All tables in the <var>package</var> schema will have their definitions and 
/// data mapped to this new database. Tables in subpackages are excluded, as are
/// tables in the designated package that aren't using extent sets (dwelling outside
/// the defaults for DDL-created tables)</p>
ClassMethod CreateDatabase(location As %String, package As %String = "AtScale", verbose As %Boolean = 1) As %Status [ SqlName = CreateDatabase, SqlProc ]
{
    set sc = $$$OK, namespace = $namespace
    try {

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

            // now register
            kill properties
            set properties("Directory") = location
            set sc = ##class(Config.Databases).Create(dbname, .properties)
            quit:$$$ISERR(sc)
        }

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

ClassMethod GetGlobalPrefix(package As %String) As %String
{
    quit $e($p($$generateExtentGlobal^%occStorageUtil(package_".dummy"),".",1),2,*)_".*"
}

}
