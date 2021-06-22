page 274 "Resource Registers"
{
    ApplicationArea = Jobs;
    Caption = 'Resource Registers';
    Editable = false;
    PageType = List;
    SourceTable = "Resource Register";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date when you posted the entries in the journal.';
                }
                field("Creation Time"; "Creation Time")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the time when you posted the entries in the journal.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Journal Batch Name"; "Journal Batch Name")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the entries were posted from.';
                }
                field("From Entry No."; "From Entry No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the first item entry number in the register.';
                }
                field("To Entry No."; "To Entry No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the last entry line that you included before you posted the entries in the journal.';
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
        area(navigation)
        {
            group("&Register")
            {
                Caption = '&Register';
                Image = Register;
                action("Resource Ledger")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource Ledger';
                    Image = ResourceLedger;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Codeunit "Res. Reg.-Show Ledger";
                    ToolTip = 'View the ledger entries for the resource.';
                }
            }
        }
        area(processing)
        {
            action("Delete Empty Resource Registers")
            {
                ApplicationArea = All;
                Caption = 'Delete Empty Resource Registers';
                Image = Delete;
                RunObject = Report "Delete Empty Res. Registers";
                ToolTip = 'Find and delete empty resource registers.';
            }
        }
    }
}

