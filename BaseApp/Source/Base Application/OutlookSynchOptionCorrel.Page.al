page 5307 "Outlook Synch. Option Correl."
{
    AutoSplitKey = true;
    Caption = 'Outlook Synch. Option Correl.';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Outlook Synch. Option Correl.";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Outlook Value"; "Outlook Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Outlook property.';
                }
                field(GetFieldValue; GetFieldValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Value';
                    Lookup = true;
                    ToolTip = 'Specifies the value of the field that will be synchronized.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        OutlookSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";
                        LookupRecRef: RecordRef;
                        LookupFieldRef: FieldRef;
                        OptionID: Integer;
                    begin
                        LookupRecRef.Open("Table No.", true);
                        LookupFieldRef := LookupRecRef.Field("Field No.");

                        OptionID := OutlookSynchSetupMgt.ShowOptionsLookup(LookupFieldRef.OptionCaption);

                        if OptionID > 0 then
                            Validate("Option No.", OptionID - 1);

                        LookupRecRef.Close;
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

