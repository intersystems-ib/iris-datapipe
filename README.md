DataPipe is an interoperability framework to ingest data in InterSystems IRIS in a flexible way.

<img src="img/datapipe-diagram2.png" width="800" />

# QuickStart
You can try out the included quickstart container to have a look at DataPipe. 

## Run container
```bash
docker compose -f docker-compose.quickstart.yml up -d
```

## Interoperability production
DataPipe uses interoperability framework.

Check [DataPipe.Test.Production](http://localhost:52773/csp/dpipe/EnsPortal.ProductionConfig.zen?PRODUCTION=DataPipe.Test.Production) interoperability production loggin-in as `superuser` / `SYS`.

Now, you only need to generate some data.

## Generate sample data
Now you can generate some sample data that will be processed in your pipes:

* Open an [WebTerminal](http://localhost:52773/terminal/) interactive session (terminal)

* Generate data
```objectscript
do ##class(DataPipe.Test.Helper).QuickStart()
```

* You can have a look at the [DataPipe.Test.Production](http://localhost:52773/csp/dpipe/EnsPortal.ProductionConfig.zen?PRODUCTION=DataPipe.Test.Production) and see how messages has been processed.

## DataPipeUI
DataPipe includes an UI that allows you to manage the data that has been processed.

Follow these steps to run [datapipeUI](https://github.com/intersystems-ib/iris-datapipeUI).

1. In other directory, clone [datapipeUI](https://github.com/intersystems-ib/iris-datapipeUI) repository

```bash
git clone https://github.com/intersystems-ib/iris-datapipeUI
```

2. Run UI container:

```bash
cd iris-datapipeUI
docker compose up -d
```

3. Log-in the UI at http://localhost:8080 using `dpadmin` / `demo`

* Have a look at the defined **Pipes**
* Check the Activity **Dashboard** 
* Try out **filtering** the records that have been processed: 
<img src="img/dp2-overview-1.gif" />

* Click on some record details and inspect **Ingestion**, **Staging** and **Operation**
* View the record history and even try to repeat some of the stages and see what happens.
<img src="img/dp2-overview-2.gif" />

# Features

## Defining Pipes
* You need to define your Pipes: set a code and some description.
* Optionally you can specify an InterSystems IRIS security resource that will be required to view that pipe.

## Processing data
When processing data you need to follow these steps:

### 1) Define a DataPipe Model
You need to define a model for the data you want to ingest. 
A model is a class that extends from [DataPipe.Model.cls](src/DataPipe/Model.cls) where you must implement some methods.

<img src="img/datapipe-model.png" width="200" />

In your model you will implement:
* How to serialize / deserialize your data (e.g. using JSON or XML).
* How to Normalize and Validate your data.
* And finally, what operation you want to run with your data after it is normalized and validated.

Have a look at these examples:
* [DataPipe.Test.HL7.Models.A08.cls](src/DataPipe/Test/HL7/Models/A08.cls) - a model for processing information of incoming HL7 messages
* [DataPipe.Test.REST.Models.Person.cls](src/DataPipe/Test/REST/Models/Person.cls) - a model for processing information of incoming REST requests with some person data

### 2) Add Interoperability components
* After defining your model, you need to setup an interoperability production using DataPipe components
* DataPipe provides Business Processes and Operations that can work with a DataPipe model.
* The only Business Process you must define is your Ingestion Process.

<img src="img/datapipe-components.png" width="800" />

#### 2.1) Create an Ingestion Process
You need to implement an **Ingestion process** using [DataPipe.Ingestion.BP.IngestionManagerContext](src/DataPipe/Ingestion/BP/IngestionManagerContext.cls) as context.

This process will receive an input and will implement:
* `Input > InboxAttributes`: 
    * Extract some input information and define the attributes of your data.
    * The **Pipe** the data belongs to is an attribute you must specify.
    * These attributes will describe your data and will be used afterwards for searching.
* `Input > Model`: 
    * Decide how your incoming data will be transformed into the DataPipe model you have previously defined.

You can find examples here:
* [DataPipe.Test.HL7.BP.HL7Ingestion.cls](src/DataPipe/Test/HL7/BP/HL7Ingestion.cls) - ingestion process for incoming HL7 messages
* [DataPipe.Test.REST.BP.RESTIngestion.cls](src/DataPipe/Test/REST/BP/RESTIngestion.cls) - ingestion process for incoming REST messages

#### 2.2) Add the rest of components
Rest of the components are provided by DataPipe you need to add are provided by DataPipe.
These components will call the different methods you have in your model.

Usually you will add:
* The Ingestion process you have implemented before.
* A [DataPipe.Staging.BP.StagingManager](src/DataPipe/Staging/BP/StagingManager.cls) process.
* A [DataPipe.Oper.BP.OperManager](src/DataPipe/Oper/BP/OperManager.cls) process.
* And a [DataPipe.Oper.BO.OperationHandler](src/DataPipe/Oper/BO/OperationHandler.cls) operation.

Have a look at a full example in [DataPipe.Test.Production.cls](src/DataPipe/Test/Production.cls)

# Installation
1) Install [IPM package manager](https://github.com/intersystems/ipm) if you don't have already done it.
2) Create a new namespace (e.g. `DPIPE`)
3) Switch to the namespace you want to install DataPipe.
4) Install DataPipe using ipm:

```objectscript
zpm "install iris-datapipe"
```

5) Set up users and roles as needed (see next section).

## Users and privileges

DataPipe uses different security resources you can assign to InterSystems IRIS user account:
* `DP_ADMIN` - DataPipe Administrator
* `DP_MENU_DASHBOARD` - Access to Dashboard menu option in UI
* `DP_MENU_SEARCH` - Access to Search menu option in UI

You can use the following as an **EXAMPLE** to set up the users in your system:

Create resources:
```objectscript
zn "%SYS"
write ##class(Security.Resources).Create("DP_ADMIN","DataPipe Admin Privilege")
write ##class(Security.Resources).Create("DP_MENU_DASHBOARD","DataPipe UI Dashboard Menu Access")
write ##class(Security.Resources).Create("DP_MENU_SEARCH","DataPipe UI Search Menu Access")
```

Create a `DataPipe_Admin` role:
```objectscript
write ##class(Security.Roles).Create("DataPipe_Admin","DataPipe Administrator","DP_ADMIN:RWU,DP_MENU_DASHBOARD:RWU,DP_MENU_SEARCH:RWU,%DB_USER:RW,%DB_IRISSYS:R")
```

Grant access to tables and views to `DataPipe_Admin` role:
```sql
GRANT INSERT,SELECT,UPDATE ON DataPipe_Data.Pipe, DataPipe_Data.Preference TO DataPipe_Admin
```

```sql
GRANT SELECT ON DataPipe_Data.VInbox, DataPipe_Data.VIngestion, DataPipe_Data.VStaging, DataPipe_Data.VOper TO DataPipe_Admin
```

Create a new user that belongs to `DataPipe_Admin` role:
```objectscript
write ##class(Security.Users).Create("dpadmin","DataPipe_Admin","demo")
```

You can also check out the [DataPipe_Admin](http://localhost:52773/csp/sys/sec/%25CSP.UI.Portal.Role.zen?PID=DataPipe_Admin) role definition in InterSystems IRIS. 

## Using DataPipe in multiple namespaces

You can install DataPipe in one namespace and use it in different namespaces using the same UI.

To do so, you need to:
* Install DataPipe in source namespace
* Map DataPipe and Restforms2 package and globals to target namespace
* Grant access to tables and views on target namespace

The following example uses the **quickstart container** to configure Datapipe also in `USER` namespace:

1) DataPipe is already installed in `DPIPE` namespace.
2) Map DataPipe and Restforms2 package and globals from `DPIPE` to `USER`:

```objectscript
zn "%SYS"

// package mapping
set props("Database")="DPIPE-DATA"
write ##class(Config.MapPackages).Create("USER", "DataPipe", .props)
write ##class(Config.MapPackages).Create("USER", "Form", .props)

// global mapping
write ##class(Config.MapGlobals).Create("USER", "DataPipe*", .props)
write ##class(Config.MapGlobals).Create("USER", "Form*", .props)

// routine mapping
write ##class(Config.MapRoutines).Create("USER", "Form*", .props)
```

3) Grant access to tables and views on `USER` namespace:

```sql
GRANT INSERT,SELECT,UPDATE ON DataPipe_Data.Pipe, DataPipe_Data.Preference TO DataPipe_Admin
```

```sql
GRANT SELECT ON DataPipe_Data.VInbox, DataPipe_Data.VIngestion, DataPipe_Data.VStaging, DataPipe_Data.VOper TO DataPipe_Admin
```

4) Load a sample production in `USER` which already have DataPipe components:

```objectscript
zn "USER"
do $system.OBJ.Load("/app/install/SampleProduction.cls", "ck")
```

5) Start the production

6) Send a test message

```objectscript
zn "USER"
write ##class(DataPipe.Test.REST.Helper).SendHTTPRequests(1, "/test/user/api/message")
```

6) Check datapipeUI

## DataPipeUI considerations

When enabling [datapipeUI](https://github.com/intersystems-ib/iris-datapipeUI), you must consider the following:

### CORS
You must consider CORS restrictions.
You can see a basic example [here](https://github.com/intersystems-ib/iris-datapipe/blob/master/src/Form/REST/Abstract.cls#L18) that allows any incoming connection (this is only recommended for testing).

### Database resource
Make sure that `CSPSystem` user in InterSystems IRIS have read permission on the resource of the database where you have installed DataPipe.

# Upgrading from previous version

See [CONTRIB.md](./CONTRIB.md) *Upgrading from previous versions* section for detailed instructions. 
