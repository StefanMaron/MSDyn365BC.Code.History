#if not CLEAN18
page 31127 "EET Entry Preview Card"
{
    Caption = 'EET Entry Preview Card (Obsolete)';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "EET Entry";
    SourceTableTemporary = true;
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
                field("Creation Datetime"; "Creation Datetime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time when the entry was created.';
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
                    ToolTip = 'Specifies the VAT base amount for base VAT rate for cash desk document.';
                }
                field("VAT Amount (Basic)"; "VAT Amount (Basic)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT amount for base VAT rate.';
                }
                field("VAT Base (Reduced)"; "VAT Base (Reduced)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT base amount for reduced VAT rate for cash desk document.';
                }
                field("VAT Amount (Reduced)"; "VAT Amount (Reduced)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT amount for reduced VAT rate.';
                }
                field("VAT Base (Reduced 2)"; "VAT Base (Reduced 2)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT base amount for reduced 2 VAT rate for cash desk document.';
                }
                field("VAT Amount (Reduced 2)"; "VAT Amount (Reduced 2)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT amount for reduced 2 VAT rate.';
                }
                field("Amount - Art.89"; "Amount - Art.89")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount under paragraph 89th.';
                }
                field("Amount (Basic) - Art.90"; "Amount (Basic) - Art.90")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount under paragraph 90th for base rate.';
                }
                field("Amount (Reduced) - Art.90"; "Amount (Reduced) - Art.90")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount under paragraph 90th for reduced rate.';
                }
                field("Amount (Reduced 2) - Art.90"; "Amount (Reduced 2) - Art.90")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount under paragraph 90th for reduced 2 rate.';
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
                field("EET Status Last Changed"; "EET Status Last Changed")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date and time of the last status change for the EET entry.';

                    trigger OnDrillDown()
                    begin
                        ShowStatusLogPreview;
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
                    ShowStatusLogPreview;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SignatureCode := GetSignatureCode;
        SetStyle;
    end;

    var
        TempEETEntryStatus: Record "EET Entry Status" temporary;
        TempErrorMessage: Record "Error Message" temporary;
        EETEntryManagement: Codeunit "EET Entry Management";
        SignatureCode: Text;
        [InDataSet]
        StyleText: Text;

    [Scope('OnPrem')]
    procedure Set(var TempEETEntryParam: Record "EET Entry" temporary; var TempEETEntryStatusParam: Record "EET Entry Status" temporary; var TempErrorMessageParam: Record "Error Message" temporary)
    begin
        Copy(TempEETEntryParam, true);
        TempEETEntryStatus.Copy(TempEETEntryStatusParam, true);
        TempErrorMessage.Copy(TempErrorMessageParam, true);
    end;

    local procedure SetStyle()
    begin
        StyleText := EETEntryManagement.GetEETStatusStyleExpr("EET Status");
    end;

    local procedure ShowStatusLogPreview()
    var
        EETEntryStatusLogPreview: Page "EET Entry Status Log Preview";
    begin
        EETEntryStatusLogPreview.Set(TempEETEntryStatus, TempErrorMessage);
        EETEntryStatusLogPreview.RunModal();
    end;
}
#endif