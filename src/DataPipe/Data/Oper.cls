Class DataPipe.Data.Oper Extends (%Persistent, %XML.Adaptor, Form.Adaptor)
{

Parameter FORMNAME = "Oper";

Parameter OBJPERMISSIONS As %String = "CRUD";

Parameter DISPLAYPROPERTY As %String = "Id";

Parameter FORMORDERBY As %String = "Id";

/// *Calculated* Id. %ID value projected to JSON
Property Id As %Integer(%JSONINCLUDE = "OUTPUTONLY") [ Calculated, SqlComputeCode = { set {*}={%%ID}}, SqlComputed ];

/// Operation Errors
Property OperErrors As list Of ErrorInfo;

/// Json Serialized OperErrors. Used in UI.
Property OperErrorsJson As %String(MAXLEN = "");

/// Operation Log
Property OperLog As %Stream.GlobalCharacter;

/// SessionId that triggered the Operation layer
Property SessionId As %String;

/// Interop. HeaderId that triggered the Operation
Property HeaderId As %String;

/// Created
Property CreatedTS As %TimeStamp;

/// Operation layer status
Property Status As %String(VALUELIST = ",N/A,PROCESSING,PROCESSED,ERROR,IGNORED") [ InitialExpression = "N/A" ];

/// Number of retries (running the operation)
Property Retries As %String [ InitialExpression = 0 ];

/// parent Staging
Relationship Staging As Staging(%JSONREFERENCE = "ID") [ Cardinality = one, Inverse = Opers ];

/// Index
Index StagingIndex On Staging;

/// Classmethod used by RESTForms2 query /form/objects/DataPipe.Data.Oper/find
ClassMethod queryFIND() As %String
{
  quit "Id, CreatedTS, HeaderId, Status, OperErrorsJson JSON@OperErrorsJson "
}

/// Serialize oper errors. Serialized errors will be used in UI.
/// This method must be called after modifying oper errors.
Method SerializeOperErrors() As %Status
{
	set ret = $$$OK
	set jsonArr=[]
	try {
		set count = ..OperErrors.Count()
		for i=1:1:count {
			set code = ..OperErrors.GetAt(i).Code
			set desc = ..OperErrors.GetAt(i).Desc
			set jsonError = code_": "_desc
			do jsonArr.%Push(jsonError)
		}
		set ..OperErrorsJson = jsonArr.%ToJSON()
		
	} catch ex {
		set sc = ex.AsStatus()
	}
	quit ret
}

Storage Default
{
<Data name="OperDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>OperErrors</Value>
</Value>
<Value name="3">
<Value>OperErrorsJson</Value>
</Value>
<Value name="4">
<Value>OperLog</Value>
</Value>
<Value name="5">
<Value>SessionId</Value>
</Value>
<Value name="6">
<Value>HeaderId</Value>
</Value>
<Value name="7">
<Value>CreatedTS</Value>
</Value>
<Value name="8">
<Value>Status</Value>
</Value>
<Value name="9">
<Value>Staging</Value>
</Value>
<Value name="10">
<Value>Retries</Value>
</Value>
</Data>
<DataLocation>^DataPipe.Data.OperD</DataLocation>
<DefaultData>OperDefaultData</DefaultData>
<IdLocation>^DataPipe.Data.OperD</IdLocation>
<IndexLocation>^DataPipe.Data.OperI</IndexLocation>
<StreamLocation>^DataPipe.Data.OperS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
