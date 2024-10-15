page 12112 "Withholding Tax Card"
{
    Caption = 'Withholding Tax Card';
    PageType = Card;
    SourceTable = "Withholding Tax";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the withholding tax entry is posted.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique identification number of the vendor that is related to the withholding tax entry.';

                    trigger OnValidate()
                    begin
                        if Vendor.Get("Vendor No.") then;
                    end;
                }
                field("Vendor.Name"; Vendor.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Name';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the vendor name.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a unique identification number that refers to the source document that generated the withholding tax entry.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an identification number, using the numbering system of the vendor, that links the vendor''s source document to the withholding tax entry.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the source document that generated the withholding tax entry.';
                }
                field("Related Date"; "Related Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the purchase that generated the withholding tax entry.';
                }
                field("Payment Date"; "Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the withholding tax amount was paid to the tax authority.';
                }
                field(Month; Month)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the month of the withholding tax entry in numeric format.';
                }
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the year of the withholding tax entry in numeric format. ';
                }
                field("Tax Code"; "Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a unique four-digit code that is used to reference the fiscal withholding tax that is applied to this entry.';
                }
                field(Reason; Reason)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code.';
                }
                field(Paid; Paid)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the withholding tax amount for this entry has been paid to the tax authority.';
                }
                field(Reported; Reported)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the withholding tax amount from this entry has been reported to the tax authority.';
                }
                field("Non-Taxable Income Type"; "Non-Taxable Income Type")
                {
                    ApplicationArea = Basic, Suite;
                    OptionCaption = ' ,,,5,6,7,8,9,10,11';
                    ToolTip = 'Specifies the type of non-taxable income.';

                    trigger OnValidate()
                    begin
                        SetBaseExcludedStyleExpr();
                    end;
                }
            }
            group("Withholding Tax")
            {
                Caption = 'Withholding Tax';
                field("Withholding Tax Code"; "Withholding Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the withholding code that is applied to this purchase. ';
                }
                field("Total Amount"; "Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to withholding tax.';
                }
                field("Base - Excluded Amount"; "Base - Excluded Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Unfavorable;
                    StyleExpr = BaseExcludedStyleExpr;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the withholding tax calculation, based on exclusions allowed by law.';

                    trigger OnDrillDown()
                    var
                        WithholdingTaxLine: Record "Withholding Tax Line";
                        ConfirmManagement: Codeunit "Confirm Management";
                        WithholdingTaxLinesPage: Page "Withholding Tax Lines";
                    begin
                        if "Non-Taxable Income Type" <> "Non-Taxable Income Type"::" " then begin
                            if not ConfirmManagement.GetResponse(ClearNonTaxableIncomeTypeQst, false) then
                                exit;
                            Validate("Non-Taxable Income Type", "Non-Taxable Income Type"::" ");
                        end;

                        WithholdingTaxLine.SetRange("Withholding Tax Entry No.", "Entry No.");
                        WithholdingTaxLinesPage.SetTableView(WithholdingTaxLine);
                        Modify(true);
                        Commit();
                        WithholdingTaxLinesPage.RunModal();
                        SetBaseExcludedStyleExpr();
                    end;

                    trigger OnValidate()
                    begin
                        SetBaseExcludedStyleExpr();
                    end;
                }
                field("Non Taxable Amount By Treaty"; "Non Taxable Amount By Treaty")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the withholding tax calculation based on residency. ';
                }
                field("Non Taxable Amount %"; "Non Taxable Amount %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the percent of the original purchase transaction that is not taxable due to provisions in the law.';
                }
                field("Non Taxable Amount"; "Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original purchase that is not taxable due to provisions in the law.';
                }
                field("Taxable Base"; "Taxable Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to withholding tax after non-taxable and excluded amounts have been subtracted.';
                }
                field("Withholding Tax %"; "Withholding Tax %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the percentage of the purchase that is subject to withholding tax.';
                }
                field("Withholding Tax Amount"; "Withholding Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of withholding tax for this purchase. ';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Navigate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View the number and type of entries that have the same document number or posting date.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Vendor.Get("Vendor No.") then;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Vendor.Init();
    end;

    trigger OnOpenPage()
    begin
        SetBaseExcludedStyleExpr();
    end;

    var
        Vendor: Record Vendor;
        ClearNonTaxableIncomeTypeQst: Label 'To distribute Non-Taxable Amount between several Income Types you must have Non-Taxable Income Type on this Withholding Tax Entry empty. \\ Do you want to clear Non-Taxable Income Type and continue?';
        BaseExcludedStyleExpr: Boolean;

    local procedure SetBaseExcludedStyleExpr()
    var
        WithholdingTaxLine: Record "Withholding Tax Line";
    begin
        if "Non-Taxable Income Type" <> "Non-Taxable Income Type"::" " then
            BaseExcludedStyleExpr := false
        else
            BaseExcludedStyleExpr := not (WithholdingTaxLine.GetAmountForEntryNo("Entry No.") = "Base - Excluded Amount");
    end;
}

