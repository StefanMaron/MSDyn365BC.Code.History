namespace Microsoft.Service.Maintenance;

xmlport 5901 "Import IRIS to Fault Codes"
{
    Caption = 'Import IRIS to Fault Codes';
    Direction = Import;
    FieldDelimiter = '<None>';
    FieldSeparator = '<TAB>';
    Format = VariableText;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement("Fault Code"; "Fault Code")
            {
                XmlName = 'FaultCode';
                fieldelement(Code; "Fault Code".Code)
                {
                }
                fieldelement(Description; "Fault Code".Description)
                {
                }

                trigger OnBeforeInsertRecord()
                begin
                    "Fault Code"."Fault Area Code" := CopyStr("Fault Code".Code, 1, 1);
                    "Fault Code"."Symptom Code" := CopyStr("Fault Code".Code, 2, 1);
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }
}

