page 31124 "EET Entry Card"
{
    Caption = 'EET Entry Card (Obsolete)';
    Editable = false;
    PageType = Card;
    SourceTable = "EET Entry";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source type of the entry.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source number of the entry.';
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
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the EET entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s document number.';
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
            }
            group(Sale)
            {
                Caption = 'Sale';
                field("Total Sales Amount"; "Total Sales Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the total amount of cash document.';
                }
                field("Amount Exempted From VAT"; "Amount Exempted From VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of cash document VAT-exempt.';
                }
                field("VAT Base (Basic)"; "VAT Base (Basic)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT base amount for cash desk document.';
                }
                field("VAT Amount (Basic)"; "VAT Amount (Basic)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base VAT amount.';
                }
                field("VAT Base (Reduced)"; "VAT Base (Reduced)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reduced VAT base amount for cash desk document.';
                }
                field("VAT Amount (Reduced)"; "VAT Amount (Reduced)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reduced VAT amount.';
                }
                field("VAT Base (Reduced 2)"; "VAT Base (Reduced 2)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reduced VAT base amount for cash desk document.';
                }
                field("VAT Amount (Reduced 2)"; "VAT Amount (Reduced 2)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reduced VAT amount 2.';
                }
                field("Amount - Art.89"; "Amount - Art.89")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount under paragraph 89th.';
                }
                field("Amount (Basic) - Art.90"; "Amount (Basic) - Art.90")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base amount under paragraph 90th.';
                }
                field("Amount (Reduced) - Art.90"; "Amount (Reduced) - Art.90")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reduced amount under paragraph 90th.';
                }
                field("Amount (Reduced 2) - Art.90"; "Amount (Reduced 2) - Art.90")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reduced amount 2 under paragraph 90th.';
                }
                field("Amt. For Subseq. Draw/Settle"; "Amt. For Subseq. Draw/Settle")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the payments for subsequent drawdown or settlement.';
                }
                field("Amt. Subseq. Drawn/Settled"; "Amt. Subseq. Drawn/Settled")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the subsequent drawing or settlement.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("EET Status"; "EET Status")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    StyleExpr = StyleText;
                    ToolTip = 'Specifies the current state of the EET entries.';
                }
                field(GetFormattedEETStatusLastChanged; GetFormattedEETStatusLastChanged)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'EET Status Last Changed';
                    Importance = Promoted;
                    ToolTip = 'Specifies the date and time of the last status change for the EET entry.';

                    trigger OnDrillDown()
                    begin
                        ShowStatusLog;
                    end;
                }
                field("Message UUID"; "Message UUID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the UUID of the data message.';
                }
                field(SignatureCode; SignatureCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Signature Code (PKP)';
                    ToolTip = 'Specifies the content of the field for the Signing code of the taxpayer.';
                }
                field("Security Code (BKP)"; "Security Code (BKP)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the content of the field for the Security code of the taxpayer.';
                }
                field("Fiscal Identification Code"; "Fiscal Identification Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the content of the field for the Fiscal identification code of the receipt.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220036; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220035; Notes)
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
                    ShowDocument;
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
                        EETConfirmation.RunModal;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SignatureCode := GetSignatureCode;
        SetStyle;
    end;

    var
        EETEntryManagement: Codeunit "EET Entry Management";
        SignatureCode: Text;
        [InDataSet]
        StyleText: Text;

    local procedure SetStyle()
    begin
        StyleText := EETEntryManagement.GetEETStatusStyleExpr("EET Status");
    end;
}

