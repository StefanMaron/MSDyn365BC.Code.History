page 6726 "OData EDM Definition Card"
{
    Caption = 'OData EDM Definition Card';
    PageType = Card;
    SourceTable = "OData Edm Type";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Key"; Key)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the Open Data Protocol EDM definition.';
                }
            }
            group(EDMDefinitionXMLGroup)
            {
                Caption = 'EDM Definition XML';
                field(EDMDefinitionXML; ODataEDMXMLTxt)
                {
                    ApplicationArea = All;
                    Caption = 'EDM Definition XML';
                    MultiLine = true;
                    ShowCaption = false;

                    trigger OnValidate()
                    begin
                        SetEDMXML(ODataEDMXMLTxt);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ODataEDMXMLTxt := GetEDMXML();
    end;

    var
        ODataEDMXMLTxt: Text;

    procedure GetEDMXML(): Text
    var
        EDMDefinitionInStream: InStream;
        EDMText: Text;
    begin
        CalcFields("Edm Xml");
        if not "Edm Xml".HasValue() then
            exit('');

        "Edm Xml".CreateInStream(EDMDefinitionInStream, TEXTENCODING::UTF8);
        EDMDefinitionInStream.Read(EDMText);
        exit(EDMText);
    end;

    procedure SetEDMXML(EDMXml: Text)
    var
        EDMDefinitionOutStream: OutStream;
    begin
        Clear("Edm Xml");
        "Edm Xml".CreateOutStream(EDMDefinitionOutStream, TEXTENCODING::UTF8);
        EDMDefinitionOutStream.WriteText(EDMXml);
        Modify(true);
    end;
}

