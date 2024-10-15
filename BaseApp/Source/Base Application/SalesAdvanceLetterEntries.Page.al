#if not CLEAN19
page 31015 "Sales Advance Letter Entries"
{
    Caption = 'Sales Advance Letter Entries (Obsolete)';
    DataCaptionExpression = GetCaption();
    Editable = false;
    PageType = List;
    SourceTable = "Sales Advance Letter Entry";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1220027)
            {
                ShowCaption = false;
                field("Template Name"; Rec."Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the template.';
                }
                field("Letter No."; Rec."Letter No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of letter.';
                }
                field("Letter Line No."; Rec."Letter Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies letter line number.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the entry.';
                    Visible = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of sales document (order, invoice).';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of sales document.';
                }
                field("Sale Line No."; Rec."Sale Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line No. of sales invoice on which is executed the advance''s deduction.';
                }
                field("Deduction Line No."; Rec."Deduction Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line No. of sales invoice on which was executed the advance''s deduction.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer account number that the entry is linked to.';
                }
                field("Customer Entry No."; Rec."Customer Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer ledger entries number that the entry is linked to.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the document number.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("User ID"; Rec."User ID")
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
                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Transaction No. assigned to all the entries involved in the same transaction.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT business posting group code.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT product posting group code for the VAT Statement.';
                }
                field("VAT Date"; Rec."VAT Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT date. This date must be shown on the VAT statement.';
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT percentage used to calculate Amount Including VAT on this line.';
                }
                field("VAT Identifier"; Rec."VAT Identifier")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT identifier.';
                }
                field("VAT Calculation Type"; Rec."VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which VAT calculation type was used when this entry was posted.';
                }
                field("VAT Base Amount"; Rec."VAT Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies VAT base amount of advance.';
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies VAT amount of advance.';
                }
                field("VAT Base Amount (LCY)"; Rec."VAT Base Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies VAT base amount of advance. The amount is in the local currency.';
                }
                field("VAT Amount (LCY)"; Rec."VAT Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies VAT amount of advance.';
                }
                field("VAT Entry No."; Rec."VAT Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of VAT entry.';
                }
                field("Entry No."; Rec."Entry No.")
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
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    NavigatePage.SetDoc("Posting Date", "Document No.");
                    NavigatePage.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
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
#endif
