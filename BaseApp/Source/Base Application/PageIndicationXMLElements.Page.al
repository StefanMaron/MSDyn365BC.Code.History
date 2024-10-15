page 26583 "Page Indication XML Elements"
{
    AutoSplitKey = true;
    Caption = 'Page Indication XML Elements';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Page Indication XML Element";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("XML Element Name"; "XML Element Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the XML element name associated with the page indication XML element.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        XMLElementLines: Page "XML Element Line List";
                    begin
                        XMLElementLine.SetCurrentKey("Report Code", "Sequence No.");
                        XMLElementLine.FilterGroup(2);
                        XMLElementLine.SetRange("Report Code", "Report Code");
                        XMLElementLine.FilterGroup(0);
                        XMLElementLine.SetRange("Table Code", "Table Code");
                        if "XML Element Line No." <> 0 then begin
                            XMLElementLine.Get("Report Code", "XML Element Line No.");
                            XMLElementLines.SetRecord(XMLElementLine);
                        end;
                        XMLElementLines.SetTableView(XMLElementLine);
                        XMLElementLines.LookupMode := true;

                        if XMLElementLines.RunModal = ACTION::LookupOK then begin
                            XMLElementLines.GetRecord(XMLElementLine);
                            "XML Element Line No." := XMLElementLine."Line No.";
                            "XML Element Name" := XMLElementLine."Element Name";
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if "XML Element Name" <> '' then begin
                            XMLElementLine.SetRange("Report Code", "Report Code");
                            XMLElementLine.SetRange("Table Code", "Table Code");
                            XMLElementLine.SetRange("Element Name", "XML Element Name");
                            XMLElementLine.FindFirst();
                            "XML Element Line No." := XMLElementLine."Line No.";
                        end else
                            "XML Element Line No." := 0;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        XMLElementLine: Record "XML Element Line";
}

