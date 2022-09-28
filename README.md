# AtScale configuration utilities

This utility class is posted here for convenience only. The full "AtScale UDAF package", including the User Defined Aggregate Functions that are essential for running Adaptive Analytics is available to customers through the [WRC downloads page](https://wrc.intersystems.com/wrc/coDistGen.csp) and [InterSystems Package Manager](https://pm.intersystems.com/). The class in this repository only contains a subset of that functionality.


## Creating a database

The following command will create a new IRIS database for storing the AtScale aggregate tables and configure it using InterSystems best practices for this type of data (disable journaling and locking, enabling parallel DML).

Sample usage

```ObjectScript
write ##class(AtScaleConfig.Utils).CreateDatabase("C:\InterSystems\IRIS\mgr\AtScale\")
```

Or

```SQL
CALL AtScaleConfig.CreateDatabase('C:\InterSystems\IRIS\mgr\AtScale')
```

See the class ref for `AtScaleConfig.Utils` for more details

## Consulting table stats

The following shorthand stored proc was added for use by AtScale. It retrieves column-level selectivity information for a particular table, gathering those statistics on the fly (and storing them) if none have been collected for this table before.

```SQL
SELECT * FROM AtScaleConfig.GetTableStats('MyTable')
```