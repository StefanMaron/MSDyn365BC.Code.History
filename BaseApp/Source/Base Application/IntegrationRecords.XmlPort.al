xmlport 5151 "Integration Records"
{
    Caption = 'Integration Records';
    DefaultNamespace = 'urn:microsoft-dynamics-nav/xmlports/IntegrationItems';
    FormatEvaluate = Xml;
    UseDefaultNamespace = true;

    schema
    {
        textelement(IntegrationRecords)
        {
            tableelement("<integration record>"; "Integration Record")
            {
                MinOccurs = Zero;
                XmlName = 'IntegrationRecord';
                fieldelement(TableID; "<Integration Record>"."Table ID")
                {
                }
                fieldelement(PageID; "<Integration Record>"."Page ID")
                {
                }
                fieldelement(IntegrationID; "<Integration Record>"."Integration ID")
                {
                }
                textelement(recid)
                {
                    MaxOccurs = Once;
                    XmlName = 'RecordID';
                }
                fieldelement(ModifiedOn; "<Integration Record>"."Modified On")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    RecID := Format("<Integration Record>"."Record ID");
                    RecordCount := RecordCount + 1;
                    if (MaxRecords > 0) and (RecordCount > MaxRecords) then
                        currXMLport.Quit;
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

    var
        MaxRecords: Integer;
        RecordCount: Integer;

    procedure SetMaxRecords("Max": Integer)
    begin
        MaxRecords := Max;
    end;
}

