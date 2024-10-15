page 11731 "Cash Document Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Cash Document Line";

    layout
    {
        area(content)
        {
            repeater(Control1220036)
            {
                ShowCaption = false;
                field("Cash Desk Event"; "Cash Desk Event")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cash desk event in the cash document lines.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the cash desk document type is payment or refund.';
                }
                field("Prepayment Type"; "Prepayment Type")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies if the cash document line represents a prepayment (Prepayment) or an advance (Advance).';
                    Visible = false;
                }
                field(Prepayment; Prepayment)
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies if the amount is prepayment.';
                    Visible = false;
                }
                field("External Document No."; "External Document No.")
                {
                    ToolTip = 'Specifies the number that the vendor uses on the invoice they sent to you or number of receipt.';
                    Visible = false;
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account thet the entry will be posted to. To see the options, choose the field.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord;
                        SetShowMandatoryConditions;
                    end;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = AccountTypeIsFilled;
                    ToolTip = 'Specifies the number of the account that the entry on the journal line will be posted to.';

                    trigger OnValidate()
                    begin
                        ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the payment order line.';
                }
                field("Description 2"; "Description 2")
                {
                    ToolTip = 'Specifies the another line for description if description is longer.';
                    Visible = false;
                }
                field("Gen. Posting Type"; "Gen. Posting Type")
                {
                    ToolTip = 'Specifies if the general posting type is purchase (Purchase) or sale (Sale).';
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ToolTip = 'Specifies a VAT business posting group code.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ToolTip = 'Specifies a VAT product posting group code for the VAT Statement.';
                    Visible = false;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ShowMandatory = AccountTypeIsFilled;
                    ToolTip = 'Specifies the total amount that the cash document line consists of.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    BlankZero = true;
                    ToolTip = 'Specifies the amount in the cash document line.';
                    Visible = false;
                }
                field("VAT Base Amount"; "VAT Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the total VAT base amount for lines. The program calculates this amount from the sum of line VAT base amount fields.';
                }
                field("VAT Amount"; "VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the VAT amount for cash desk document line.';
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies the code of the Shortcut Dimension 1, which is defined in the Shortcut Dimension 1 Code field in the General Ledger Setup window.';
                    Visible = DimVisible1;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupShortcutDimCode(1, "Shortcut Dimension 1 Code");
                    end;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
                    end;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies the code of the Shortcut Dimension 2, which is defined in the Shortcut Dimension 2 Code field in the General Ledger Setup window.';
                    Visible = DimVisible2;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupShortcutDimCode(2, "Shortcut Dimension 2 Code");
                    end;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
                    end;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies shortcut dimension code No. 3 of line';
                    Visible = DimVisible3;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies shortcut dimension code No. 4 of line';
                    Visible = DimVisible4;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies shortcut dimension code No. 5 of line';
                    Visible = DimVisible5;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies shortcut dimension code No. 6 of line';
                    Visible = DimVisible6;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies shortcut dimension code No. 7 of line';
                    Visible = DimVisible7;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies shortcut dimension code No. 8 of line';
                    Visible = DimVisible8;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("Salespers./Purch. Code"; "Salespers./Purch. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which salesperson is assigned to the cash document line.';
                }
                field("Posting Group"; "Posting Group")
                {
                    ToolTip = 'Specifies the posting group that will be used in posting the journal line.The field is used only if the account type is either customer or vendor.';
                    Visible = false;
                }
                field("Applies-To Doc. Type"; "Applies-To Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the payment will be applied to an already-posted document. The field is used only if the account type is a customer or vendor account.';
                }
                field("Applies-To Doc. No."; "Applies-To Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the cash document line will be applied to an already-posted document.';
                }
                field("Applies-to ID"; "Applies-to ID")
                {
                    ToolTip = 'Specifies the ID to apply to the general ledger entry.';
                    Visible = false;
                }
                field("EET Transaction"; "EET Transaction")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the value of Yes will automatically be filled when the row meets the conditions for a recorded sale.';
                    Visible = false;
                }
                field("Depreciation Book Code"; "Depreciation Book Code")
                {
                    ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
                    Visible = false;
                }
                field("FA Posting Type"; "FA Posting Type")
                {
                    OptionCaption = ' ,Acquisition Cost,,,,,Custom 2,,Maintenance';
                    ToolTip = 'Specifies if the cash document line amount represents a acquisition cost (Acquisition Cost) or a depreciation (Depreciation) or a write down (Write-Down) or an appreciation (Appreciation) or a custom 1 (Custom 1) or a custom 2 (Custom 2) or a disposal (Disposal) or a maintenance (Maintenance).';
                    Visible = false;
                }
                field("Duplicate in Depreciation Book"; "Duplicate in Depreciation Book")
                {
                    ToolTip = 'Specifies if you have selected Fixed Asset in the Account Type field for this line.';
                    Visible = false;
                }
                field("Use Duplication List"; "Use Duplication List")
                {
                    ToolTip = 'Specifies if you have selected Fixed Asset in the Account Type field for this line.';
                    Visible = false;
                }
                field("Maintenance Code"; "Maintenance Code")
                {
                    ToolTip = 'Specifies a maintenance code.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ToolTip = 'Specifies the reason code on the entry.';
                    Visible = false;
                }
            }
            group(Control1220046)
            {
                ShowCaption = false;
                field("TotalCashDocumentHeader.""VAT Base Amount"""; TotalCashDocumentHeader."VAT Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = TotalCashDocumentHeader."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = DocumentTotals.GetTotalExclVATCaption(TotalCashDocumentHeader."Currency Code");
                    Caption = 'Total Amount Excl. VAT';
                    Editable = false;
                    ToolTip = 'Specifies the total amout excl. VAT.';
                }
                field(VATAmount; VATAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = TotalCashDocumentHeader."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = DocumentTotals.GetTotalVATCaption(TotalCashDocumentHeader."Currency Code");
                    Caption = 'Total VAT';
                    Editable = false;
                    ToolTip = 'Specifies the total amout of VAT.';
                }
                field("TotalCashDocumentHeader.""Amount Including VAT"""; TotalCashDocumentHeader."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = TotalCashDocumentHeader."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = DocumentTotals.GetTotalInclVATCaption(TotalCashDocumentHeader."Currency Code");
                    Caption = 'Total Amount Incl. VAT';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the total amout incl. VAT.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Line)
            {
                Caption = 'Line';
                Image = Line;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit the dimension sets that are set up for the cash document.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Apply Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Entries';
                    Image = ApplyEntries;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'The function allows to apply customer''s or vendor''s entries.';

                    trigger OnAction()
                    begin
                        ApplyEntries;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        DocumentTotals.CalculateCashDocumentTotals(TotalCashDocumentHeader, VATAmount, Rec);
        SetShowMandatoryConditions;
    end;

    trigger OnAfterGetRecord()
    begin
        ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    begin
        SetDimensionsVisibility;
    end;

    var
        TotalCashDocumentHeader: Record "Cash Document Header";
        DocumentTotals: Codeunit "Document Totals";
        ShortcutDimCode: array[8] of Code[20];
        AccountTypeIsFilled: Boolean;
        VATAmount: Decimal;
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;

    [Scope('OnPrem')]
    procedure ShowStatistics()
    begin
        ExtStatistics;
    end;

    [Scope('OnPrem')]
    procedure UpdatePage(SetSaveRecord: Boolean)
    begin
        CurrPage.Update(SetSaveRecord);
    end;

    [Scope('OnPrem')]
    procedure LinkAdvLetters()
    begin
        LinkToAdvLetter;
    end;

    [Scope('OnPrem')]
    procedure LinkWholeAdvLetter()
    begin
        LinkWholeLetter;
    end;

    [Scope('OnPrem')]
    procedure UnLinkLinkedAdvLetters()
    begin
        UnLinkWholeLetter;
    end;

    [Scope('OnPrem')]
    procedure SetShowMandatoryConditions()
    begin
        AccountTypeIsFilled := "Account Type" <> "Account Type"::" ";
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;
}

