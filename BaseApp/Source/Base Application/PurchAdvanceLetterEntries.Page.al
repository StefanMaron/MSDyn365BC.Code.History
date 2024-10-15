page 31035 "Purch. Advance Letter Entries"
{
    Caption = 'Purch. Advance Letter Entries';
    DataCaptionExpression = GetCaption;
    Editable = false;
    PageType = List;
    SourceTable = "Purch. Advance Letter Entry";

    layout
    {
        area(content)
        {
            repeater(Control1220027)
            {
                ShowCaption = false;
                field("Template Name"; "Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the template.';
                }
                field("Letter No."; "Letter No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of letter.';
                }
                field("Letter Line No."; "Letter Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies letter line number.';
                }
                field("Entry Type"; "Entry Type")
                {
                    ToolTip = 'Specifies the type of the entry.';
                    Visible = false;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of purchase document (order, invoice).';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of purchase document.';
                }
                field("Purchase Line No."; "Purchase Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line No. of sales invoice on which is executed the advance''s deduction.';
                }
                field("Deduction Line No."; "Deduction Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line No. of purchase invoice on which was executed the advance''s deduction.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor account number that the entry is linked to.';
                }
                field("Vendor Entry No."; "Vendor Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor ledger entries number that the entry is linked to.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the document number.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user associated with the entry.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Transaction No."; "Transaction No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Transaction No. assigned to all the entries involved in the same transaction.';
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT business posting group code.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT product posting group code for the VAT Statement.';
                }
                field("VAT Date"; "VAT Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT date. This date must be shown on the VAT statement.';
                }
                field("VAT %"; "VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT percentage used to calculate Amount Including VAT on this line.';
                }
                field("VAT Identifier"; "VAT Identifier")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT identifier.';
                }
                field("VAT Calculation Type"; "VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which VAT calculation type was used when this entry was posted.';
                }
                field("VAT Base Amount"; "VAT Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies VAT base amount of advance.';
                }
                field("VAT Amount"; "VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies VAT amount of advance.';
                }
                field("VAT Base Amount (LCY)"; "VAT Base Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies VAT base amount of advance. The amount is in the local currency.';
                }
                field("VAT Amount (LCY)"; "VAT Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies VAT amount of advance.';
                }
                field("VAT Entry No."; "VAT Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of VAT entry.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number that is assigned to the entry.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    NavigatePage.SetDoc("Posting Date", "Document No.");
                    NavigatePage.Run;
                end;
            }
        }
    }

    var
        NavigatePage: Page Navigate;
        CaptionTxt: Label '%1 %2', Comment = '%1 %2';

    [Scope('OnPrem')]
    procedure GetCaption(): Text[250]
    var
        CurrDocNo: Code[20];
        EntryType: Text;
    begin
        if GetFilter("Letter No.") = '' then
            CurrDocNo := ''
        else
            if GetRangeMin("Letter No.") = GetRangeMax("Letter No.") then
                CurrDocNo := GetRangeMin("Letter No.")
            else
                CurrDocNo := '';
        EntryType := GetFilter("Entry Type");

        exit(StrSubstNo(CaptionTxt, EntryType, CurrDocNo));
    end;
}

