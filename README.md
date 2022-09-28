# AtScale configuration utilities

This utility class is posted here for convenience only. The full "AtScale UDAF package", including the User Defined Aggregate Functions that are essential for running Adaptive Analytics is available to customers through the [WRC downloads page](https://wrc.intersystems.com/wrc/coDistGen.csp) and [InterSystems Package Manager](https://pm.intersystems.com/).


## Usage

Sample usage

```ObjectScript
write ##class(AtScaleConfig.Utils).CreateDatabase("C:\InterSystems\IRIS\mgr\AtScale\")
```

Or

```SQL
CALL AtScaleConfig.CreateDatabase('C:\InterSystems\IRIS\mgr\AtScale')
```

See the class ref for `AtScaleConfig.Utils` for more details