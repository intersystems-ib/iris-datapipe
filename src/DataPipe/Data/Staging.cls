Class DataPipe.Data.Staging Extends (%Persistent, %XML.Adaptor, Form.Adaptor)
{

Parameter FORMNAME = "Staging";

Parameter OBJPERMISSIONS As %String = "R";

Parameter DISPLAYPROPERTY As %String = "Id";

Parameter FORMORDERBY As %String = "Id";

/// *Calculated* Id. %ID value projected to JSON
Property Id As %Integer(%JSONINCLUDE = "OUTPUTONLY") [ Calculated, SqlComputeCode = { set {*}={%%ID}}, SqlComputed ];

/// Normalized data model (serialized)
Property ModelNormData As %Stream.GlobalCharacter;

/// Validation Errors
Property ValidationErrors As list Of ErrorInfo;

/// Json Serialized ValidationErrors. Used in UI.
Property ValidationErrorsJson As %String(MAXLEN = "");

/// SessionId that triggered the Staging layer
Property SessionId As %String;

/// Interop. HeaderId that triggered the Staging
Property HeaderId As %String;

/// Created
Property CreatedTS As %TimeStamp;

/// Staging layer status
Property Status As %String(VALUELIST = ",N/A,VALID,INVALID,WARNING") [ InitialExpression = "N/A" ];

/// parent Ingestion
Relationship Ingestion As Ingestion(%JSONREFERENCE = "ID") [ Cardinality = one, Inverse = Stagings ];

/// Related Opers
Relationship Opers As Oper(%JSONREFERENCE = "ID") [ Cardinality = many, Inverse = Staging ];

/// Index
Index IngestionIndex On Ingestion;

/// Open callback. Check user can access record in view
Method %OnOpen() As %Status [ Private, ServerOnly = 1 ]
{
	set id = ..%Id()
    &sql(SELECT id1 INTO :idObj FROM DataPipe_Data.VStaging WHERE id1 = :id)
	if idObj="" $$$ThrowStatus($$$ERROR($$$GeneralError, "Not authorized"))
	return $$$OK
}

/// RESTForms2 query /form/objects/DataPipe.Data.Staging/custom/find
ClassMethod customqueryFIND() As %String
{
	// get parameters
	set filter = $get(%request.Data("filter",1))
	set collation = $get(%request.Data("collation",1))
	
	// where
	$$$ThrowOnError(##class(Form.JSON.SQL).ParseWhere(filter, collation, "DataPipe.Data.Staging", .where))
	
	set sql = "SELECT Id1 Id, CreatedTS, HeaderId, Status, nvl(ValidationErrorsJson,'[]') JSON@ValidationErrorsJson FROM DataPipe_Data.VStaging "_where
	return sql
}

/// Serialize validation errors. Serialized errors will be used in UI.
/// This method must be called after modifying validation errors.
Method SerializeValidationErrors() As %Status
{
	set ret = $$$OK
	set jsonArr=[]
	try {
    set count = ..ValidationErrors.Count()
	for i=1:1:count {
	  set err = ..ValidationErrors.GetAt(i)
      set code = err.Code
      set desc = err.Desc
      set jsonError = code_": "_desc
      do jsonArr.%Push(jsonError)
	}
	set ..ValidationErrorsJson = jsonArr.%ToJSON()
		
	} catch ex {
		set sc = ex.AsStatus()
	}
	quit ret
}

Storage Default
{
<Data name="StagingDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ModelNormData</Value>
</Value>
<Value name="3">
<Value>ValidationErrors</Value>
</Value>
<Value name="4">
<Value>SessionId</Value>
</Value>
<Value name="5">
<Value>HeaderId</Value>
</Value>
<Value name="6">
<Value>CreatedTS</Value>
</Value>
<Value name="7">
<Value>Status</Value>
</Value>
<Value name="8">
<Value>ValidationErrorsJson</Value>
</Value>
<Value name="9">
<Value>Ingestion</Value>
</Value>
</Data>
<DataLocation>^DataPipe.Data.StagingD</DataLocation>
<DefaultData>StagingDefaultData</DefaultData>
<IdLocation>^DataPipe.Data.StagingD</IdLocation>
<IndexLocation>^DataPipe.Data.StagingI</IndexLocation>
<StreamLocation>^DataPipe.Data.StagingS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
