page 31044 "FA History Entries"
{
    Caption = 'FA History Entries';
    DataCaptionFields = "FA No.";
    Editable = false;
    PageType = List;
    SourceTable = "FA History Entry";

    layout
    {
        area(content)
        {
            repeater(Control1220011)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the type of posting descriptions';
                }
                field("FA No."; "FA No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the fixed asset entry number.';
                }
                field("Old Value"; "Old Value")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the original fixed asset value before changes were made.';
                }
                field("New Value"; "New Value")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies new code for the fixed asset location.';
                }
                field("Closed by Entry No."; "Closed by Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the entries number whitch the document was closed.';
                    Visible = false;
                }
                field(Disposal; Disposal)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies disposal entries';
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the creation date for the fixed asset entry.';
                }
                field("Creation Time"; "Creation Time")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the creation time for the fixed asset entry.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the ID of the user associated with the entry.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the entry number that is assigned to the entry.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Print)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Print';
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    FAHistoryEntry: Record "FA History Entry";
                begin
                    FAHistoryEntry := Rec;
                    CurrPage.SetSelectionFilter(FAHistoryEntry);
                    REPORT.Run(REPORT::"FA Assignment/Discharge", true, false, FAHistoryEntry);
                end;
            }
        }
    }
}

