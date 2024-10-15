page 26589 "Compound XML Element Lines"
{
    AutoSplitKey = true;
    Caption = 'Compound XML Element Lines';
    PageType = List;
    SourceTable = "XML Element Expression Line";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("XML Element Name"; Rec."XML Element Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name associated with the XML structure of the file that will be exported.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        XMLElementLines: Page "XML Element Lines";
                    begin
                        XMLElementLine.Reset();
                        XMLElementLine.FilterGroup(2);
                        XMLElementLine.SetRange("Report Code", "Report Code");
                        XMLElementLine.SetFilter("Line No.", '<>%1', "Base XML Element Line No.");
                        XMLElementLine.FilterGroup(0);
                        XMLElementLines.SetTableView(XMLElementLine);
                        XMLElementLines.LookupMode := true;

                        if "XML Element Line No." <> 0 then begin
                            if XMLElementLine.Get("Report Code", "XML Element Line No.") then
                                XMLElementLines.SetRecord(XMLElementLine);
                        end;

                        if XMLElementLines.RunModal() = ACTION::LookupOK then begin
                            XMLElementLines.GetRecord(XMLElementLine);
                            "XML Element Line No." := XMLElementLine."Line No.";
                            "XML Element Name" := XMLElementLine."Element Name";
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if "XML Element Name" <> '' then begin
                            XMLElementLine.Reset();
                            XMLElementLine.SetRange("Report Code", "Report Code");
                            XMLElementLine.SetRange("Element Name", "XML Element Name");
                            XMLElementLine.FindFirst();
                            "XML Element Line No." := XMLElementLine."Line No.";
                        end else
                            "XML Element Line No." := 0;
                    end;
                }
                field("String Before"; Rec."String Before")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the string that is before the line on which the XML expression is based.';

                    trigger OnValidate()
                    begin
                        if SpaceEntered then begin
                            "String After" := ' ';
                            SpaceEntered := false;
                        end;
                    end;
                }
                field("String After"; Rec."String After")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the string that is after the line on which the XML expression is based.';

                    trigger OnValidate()
                    begin
                        if SpaceEntered then begin
                            "String After" := ' ';
                            SpaceEntered := false;
                        end;
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
        SpaceEntered: Boolean;
}

