#if not CLEAN18
page 31123 "EET Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'EET Entries (Obsolete)';
    CardPageID = "EET Entry Card";
    Editable = false;
    PageType = List;
    SourceTable = "EET Entry";
    UsageCategory = History;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source type of the entry.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the cash bank account for the entry.';
                }
                field("Business Premises Code"; "Business Premises Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the business premises.';
                }
                field("Cash Register Code"; "Cash Register Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the EET cash register.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s document number.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the EET entry.';
                }
                field("Total Sales Amount"; "Total Sales Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of cash document.';
                }
                field("Amount Exempted From VAT"; "Amount Exempted From VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of cash document VAT-exempt.';
                }
                field("Applied Document Type"; "Applied Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the applied document.';
                }
                field("Applied Document No."; "Applied Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the applied document.';
                }
                field("Receipt Serial No."; "Receipt Serial No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the serial no. of the EET receipt.';
                }
                field("EET Status"; "EET Status")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleText;
                    ToolTip = 'Specifies the current state of the EET entries.';
                }
                field(GetFormattedEETStatusLastChanged; GetFormattedEETStatusLastChanged)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'EET Status Last Changed';
                    ToolTip = 'Specifies the date and time of the last status change for the EET entry.';

                    trigger OnDrillDown()
                    begin
                        ShowStatusLog;
                    end;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who created the entry.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field(GetFormattedCreationDatetime; GetFormattedCreationDatetime)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Creation Datetime';
                    ToolTip = 'Specifies the date and time when the entry was created.';
                }
                field("Canceled By Entry No."; "Canceled By Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Simple Registration"; "Simple Registration")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the EET entry number.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220034; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220033; Notes)
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
            action("Entry Status Log")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Entry Status Log';
                Image = Status;
                ToolTip = 'Displays a log of the EET entry status changes.';

                trigger OnAction()
                begin
                    ShowStatusLog;
                end;
            }
            action("Show Document")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Document';
                Image = Document;
                ToolTip = 'Displays the document related to the entry.';

                trigger OnAction()
                begin
                    exit;
                end;
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Send To Register")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send To Register';
                    Image = SendElectronicDocument;
                    ToolTip = 'Sends the selected entry to the EET service to register.';

                    trigger OnAction()
                    begin
                        SendToService(false);
                        CurrPage.Update(false);
                    end;
                }
                action("Send To Verification")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send To Verification';
                    Image = SendApprovalRequest;
                    ToolTip = 'Sends the selected entry to the EET service to verification.';

                    trigger OnAction()
                    begin
                        SendToService(true);
                    end;
                }
                action(SimpleCancelEntry)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send Simple Cancel Entry';
                    Image = CancelledEntries;
                    ToolTip = 'Sends the selected entry to the EET service to cancel.';

                    trigger OnAction()
                    var
                        EETEntryManagement: Codeunit "EET Entry Management";
                    begin
                        EETEntryManagement.CreateCancelEETEntry("Entry No.", true, true);
                    end;
                }
                action(SimpleRegistration)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Simple EET Registration';
                    Image = ReverseRegister;
                    RunObject = Page "EET Simple Registration";
                    ToolTip = 'Create simple EET entry.';
                }
            }
            group(Print)
            {
                Caption = '&Print';
                Image = Print;
                action(PrintConfirmation)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print Confirmation';
                    Image = PrintReport;
                    ToolTip = 'Print Confirmation EET Entry';

                    trigger OnAction()
                    var
                        EETEntry: Record "EET Entry";
                        EETConfirmation: Report "EET Confirmation";
                    begin
                        EETEntry := Rec;
                        EETEntry.SetRecFilter;
                        EETConfirmation.SetTableView(EETEntry);
                        EETConfirmation.RunModal();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStyle;
    end;

    var
        EETEntryManagement: Codeunit "EET Entry Management";
        [InDataSet]
        StyleText: Text;

    local procedure SetStyle()
    begin
        StyleText := EETEntryManagement.GetEETStatusStyleExpr("EET Status");
    end;
}
#endif