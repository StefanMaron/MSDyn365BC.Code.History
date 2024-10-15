#if not CLEAN18
page 9401 "VAT Amount Lines"
{
    Caption = 'VAT Amount Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "VAT Amount Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("VAT Identifier"; "VAT Identifier")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contents of this field from the VAT Identifier field in the VAT Posting Setup table.';
                    Visible = false;
                }
                field("VAT %"; "VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT % that was used on the sales or purchase lines with this VAT Identifier.';
                }
                field("VAT Calculation Type"; "VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how VAT will be calculated for purchases or sales of items with this particular combination of VAT business posting group and VAT product posting group.';
                    Visible = false;
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the net VAT amount that must be paid for products on the line.';
                }
                field("Inv. Disc. Base Amount"; "Inv. Disc. Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the invoice discount base amount.';
                    Visible = false;
                }
                field("Invoice Discount Amount"; "Invoice Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Editable = InvoiceDiscountAmountEditable;
                    ToolTip = 'Specifies the invoice discount amount for a specific VAT identifier.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CalcVATFields(CurrencyCode, PricesIncludingVAT, VATBaseDiscPct);
                        ModifyRec("Modified (LCY)"); // NAVCZ
                    end;
                }
                field("VAT Base"; "VAT Base")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total net amount (amount excluding VAT) for sales or purchase lines with a specific VAT Identifier.';
                }
                field("VAT Amount"; "VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Editable = VATAmountEditable;
                    ToolTip = 'Specifies the amount of VAT that is included in the total amount.';

                    trigger OnValidate()
                    begin
                        if AllowVATDifference and not AllowVATDifferenceOnThisTab then
                            Error(Text000, FieldCaption("VAT Amount"));

                        if PricesIncludingVAT then
                            "VAT Base" := "Amount Including VAT" - "VAT Amount"
                        else
                            "Amount Including VAT" := "VAT Amount" + "VAT Base";
                        // NAVCZ
                        if CurrencyCode <> '' then begin
                            "Amount Including VAT (LCY)" := Round("Amount Including VAT" / CurrencyFactor, Currency."Amount Rounding Precision");
                            "VAT Base (LCY)" := Round("VAT Base" / CurrencyFactor, Currency."Amount Rounding Precision");
                            "Calculated VAT Amount (LCY)" := Round("Amount Including VAT (LCY)" - "VAT Base (LCY)", Currency."Amount Rounding Precision");
                            "VAT Amount (LCY)" := RoundVAT("Calculated VAT Amount (LCY)");
                            "VAT Difference (LCY)" := "VAT Amount (LCY)" - "Calculated VAT Amount (LCY)";
                        end;
                        // NAVCZ
                        FormCheckVATDifference;
                        // NAVCZ
                        "Modified (LCY)" := true;
                        ModifyRec("Modified (LCY)");
                        // NAVCZ
                    end;
                }
                field("Calculated VAT Amount"; "Calculated VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the calculated VAT amount and is only used for reference when the user changes the VAT Amount manually.';
                    Visible = false;
                }
                field("VAT Difference"; "VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the difference between the calculated VAT amount and a VAT amount that you have entered manually.';
                    Visible = false;
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total of the amounts, including VAT, on all the lines on the document.';

                    trigger OnValidate()
                    begin
                        FormCheckVATDifference;
                    end;
                }
                field("VAT Amount (LCY)"; "VAT Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = VATAmountLCYEditable;
                    ToolTip = 'Specifies the amount of VAT included in the total amount, expressed in LCY.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Unsupported functionality. The function for adjusting VAT on document statistics will be discontinued.';
                    ObsoleteTag = '18.0';

                    trigger OnValidate()
                    begin
                        // NAVCZ
                        if AllowVATDifference and not AllowVATDifferenceOnThisTab then
                            Error(Text000, FieldCaption("VAT Amount"));

                        if Currency.Code = '' then begin
                            Validate("VAT Amount", "VAT Amount (LCY)");
                            if PricesIncludingVAT then begin
                                "VAT Base" := "Amount Including VAT" - "VAT Amount";
                                "VAT Base (LCY)" := "VAT Base";
                            end else begin
                                "Amount Including VAT" := "VAT Amount" + "VAT Base";
                                "Amount Including VAT (LCY)" := "Amount Including VAT";
                            end;
                        end;

                        FormCheckVATDifferenceLCY;
                        "Modified (LCY)" := true;
                        ModifyRec("Modified (LCY)");
                        // NAVCZ
                    end;
                }
                field("VAT Difference (LCY)"; "VAT Difference (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies difference amount of VAT.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Unsupported functionality. The function for adjusting VAT on document statistics will be discontinued.';
                    ObsoleteTag = '18.0';
                }
                field("Ext. VAT Amount (LCY)"; "Ext. VAT Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = ExtVATAmountLCYEditable;
                    ToolTip = 'Specifies ext. vat amount in LCY';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Unsupported functionality. The function for adjusting VAT on document statistics will be discontinued.';
                    ObsoleteTag = '18.0';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        // NAVCZ
#if CLEAN17
                        if CurrencyCode = '' then
#else
                        if (CurrencyFactor = VATCurrencyFactor) or (VATCurrencyFactor = 0) or (CurrencyCode = '') then
#endif
                            Validate("VAT Amount (LCY)", "Ext. VAT Amount (LCY)");

                        if AllowVATDifference and not AllowVATDifferenceOnThisTab then
                            Error(Text000, FieldCaption("VAT Amount"));

                        FormCheckVATDifferenceLCY;
                        "Modified (LCY)" := true;
                        ModifyRec("Modified (LCY)");
                        // NAVCZ
                    end;
                }
                field("Ext. VAT Difference (LCY)"; "Ext. VAT Difference (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies ext. vat difference in LCY';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Unsupported functionality. The function for adjusting VAT on document statistics will be discontinued.';
                    ObsoleteTag = '18.0';
                    Visible = false;
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

    trigger OnAfterGetRecord()
    begin
        VATAmountEditable := AllowVATDifference and not "Includes Prepayment";
        InvoiceDiscountAmountEditable := AllowInvDisc and not "Includes Prepayment";
#if not CLEAN17
        // NAVCZ
        VATAmountLCYEditable := AllowVATDifferenceOnThisTab;
        if VATAmountLCYEditable then
            VATAmountLCYEditable := not UseExtAmount;
        ExtVATAmountLCYEditable :=
          AllowVATDifference and not "Includes Prepayment" and UseExtAmount;
        // NAVCZ
#endif
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        TempVATAmountLine.Copy(Rec);
        if TempVATAmountLine.Find(Which) then begin
            Rec := TempVATAmountLine;
            exit(true);
        end;
        exit(false);
    end;

    trigger OnInit()
    begin
        InvoiceDiscountAmountEditable := true;
        VATAmountEditable := true;
        VATAmountLCYEditable := true; // NAVCZ
        ExtVATAmountLCYEditable := true; // NAVCZ
    end;

    trigger OnModifyRecord(): Boolean
    begin
        ModifyRec("Modified (LCY)"); // NAVCZ
        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        TempVATAmountLine.Copy(Rec);
        ResultSteps := TempVATAmountLine.Next(Steps);
        if ResultSteps <> 0 then
            Rec := TempVATAmountLine;
        exit(ResultSteps);
    end;

    var
        Text000: Label '%1 can only be modified on the Invoicing tab.';
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        CurrencyCode: Code[10];
        AllowVATDifference: Boolean;
        AllowVATDifferenceOnThisTab: Boolean;
        PricesIncludingVAT: Boolean;
        AllowInvDisc: Boolean;
        VATBaseDiscPct: Decimal;
        [InDataSet]
        VATAmountEditable: Boolean;
        [InDataSet]
        InvoiceDiscountAmountEditable: Boolean;
        Text001: Label 'The total %1 for a document must not exceed the value %2 in the %3 field.';
        CurrencyFactor: Decimal;
        [InDataSet]
        VATAmountLCYEditable: Boolean;
        [InDataSet]
        ExtVATAmountLCYEditable: Boolean;
#if not CLEAN17
        VATCurrencyFactor: Decimal;
        UseExtAmount: Boolean;
#endif

    procedure SetTempVATAmountLine(var NewVATAmountLine: Record "VAT Amount Line")
    begin
        TempVATAmountLine.DeleteAll();
        if NewVATAmountLine.Find('-') then
            repeat
                TempVATAmountLine.Copy(NewVATAmountLine);
                TempVATAmountLine.Insert();
            until NewVATAmountLine.Next() = 0;
    end;

    procedure GetTempVATAmountLine(var NewVATAmountLine: Record "VAT Amount Line")
    begin
        NewVATAmountLine.DeleteAll();
        if TempVATAmountLine.Find('-') then
            repeat
                NewVATAmountLine.Copy(TempVATAmountLine);
                NewVATAmountLine.Insert();
            until TempVATAmountLine.Next() = 0;
    end;

    procedure InitGlobals(NewCurrencyCode: Code[10]; NewAllowVATDifference: Boolean; NewAllowVATDifferenceOnThisTab: Boolean; NewPricesIncludingVAT: Boolean; NewAllowInvDisc: Boolean; NewVATBaseDiscPct: Decimal)
    begin
        CurrencyCode := NewCurrencyCode;
        AllowVATDifference := NewAllowVATDifference;
        AllowVATDifferenceOnThisTab := NewAllowVATDifferenceOnThisTab;
        PricesIncludingVAT := NewPricesIncludingVAT;
        AllowInvDisc := NewAllowInvDisc;
        VATBaseDiscPct := NewVATBaseDiscPct;
        VATAmountEditable := AllowVATDifference;
        InvoiceDiscountAmountEditable := AllowInvDisc;
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(CurrencyCode);
    end;

    local procedure FormCheckVATDifference()
    var
        VATAmountLine2: Record "VAT Amount Line";
        TotalVATDifference: Decimal;
    begin
        CheckVATDifference(CurrencyCode, AllowVATDifference);
        VATAmountLine2 := TempVATAmountLine;
        TotalVATDifference := Abs("VAT Difference") - Abs(xRec."VAT Difference");
        if TempVATAmountLine.Find('-') then
            repeat
                TotalVATDifference := TotalVATDifference + Abs(TempVATAmountLine."VAT Difference");
            until TempVATAmountLine.Next() = 0;
        TempVATAmountLine := VATAmountLine2;
        if TotalVATDifference > Currency."Max. VAT Difference Allowed" then
            Error(
              Text001, FieldCaption("VAT Difference"),
              Currency."Max. VAT Difference Allowed", Currency.FieldCaption("Max. VAT Difference Allowed"));
    end;

    [Scope('OnPrem')]
    [Obsolete('Unsupported functionality. The function for adjusting VAT on document statistics is discontinued.', '18.0')]
    procedure FormCheckVATDifferenceLCY()
    var
        VATAmountLine2: Record "VAT Amount Line";
        GLSetup: Record "General Ledger Setup";
        TotalVATDifference: Decimal;
    begin
        // NAVCZ
        CheckVATDifferenceLCY(AllowVATDifference);
        VATAmountLine2 := TempVATAmountLine;
        TotalVATDifference := Abs("VAT Difference (LCY)") - Abs(xRec."VAT Difference (LCY)");
        if TempVATAmountLine.Find('-') then
            repeat
                TotalVATDifference := TotalVATDifference + Abs(TempVATAmountLine."VAT Difference (LCY)");
            until TempVATAmountLine.Next() = 0;
        TempVATAmountLine := VATAmountLine2;
        GLSetup.Get();
        if TotalVATDifference > GLSetup."Max. VAT Difference Allowed" then
            Error(
              Text001, FieldCaption("VAT Difference (LCY)"),
              GLSetup.FieldCaption("Max. VAT Difference Allowed"), GLSetup."Max. VAT Difference Allowed");
        // NAVCZ
    end;

    local procedure ModifyRec(ModifyLCY: Boolean)
    begin
        TempVATAmountLine := Rec;
        TempVATAmountLine.Modified := true;
        TempVATAmountLine.Modify();
        TempVATAmountLine.ModifyAll("Modified (LCY)", ModifyLCY); // NAVCZ
    end;

    [Scope('OnPrem')]
    [Obsolete('Unsupported functionality. The function for adjusting VAT on document statistics is discontinued.', '18.0')]
    procedure SetCurrencyFactor(NewCurrencyFactor: Decimal)
    begin
        CurrencyFactor := NewCurrencyFactor; // NAVCZ
    end;
#if not CLEAN17

    [Obsolete('Unsupported functionality. The function for adjusting VAT on document statistics is discontinued.', '17.5')]
    [Scope('OnPrem')]
    procedure SetVATCurrencyFactor(NewVATCurrencyFactor: Decimal)
    begin
        // NAVCZ
        VATCurrencyFactor := NewVATCurrencyFactor;
        UseExtAmount := true;
        // NAVCZ
    end;
#endif
}

#endif