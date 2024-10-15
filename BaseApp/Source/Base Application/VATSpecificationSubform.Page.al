#if not CLEAN18
page 576 "VAT Specification Subform"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "VAT Amount Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("VAT Identifier"; "VAT Identifier")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the contents of this field from the VAT Identifier field in the VAT Posting Setup table.';
                    Visible = false;
                }
                field("VAT %"; "VAT %")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT percentage that was used on the sales or purchase lines with this VAT Identifier.';
                }
                field("VAT Calculation Type"; "VAT Calculation Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies how VAT will be calculated for purchases or sales of items with this particular combination of VAT business posting group and VAT product posting group.';
                    Visible = false;
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total amount for sales or purchase lines with a specific VAT identifier.';
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
                            if ParentControl = PAGE::"Service Order Statistics" then
                                Error(Text000, FieldCaption("VAT Amount"), Text002)
                            else
                                Error(Text000, FieldCaption("VAT Amount"), Text003);

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
                        "Modified (LCY)" := true; // NAVCZ
                        ModifyRec("Modified (LCY)"); // NAVCZ
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
                    ToolTip = 'Specifies the net amount, including VAT, for this line.';

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
                            if ParentControl = PAGE::"Service Order Statistics" then
                                Error(Text000, FieldCaption("VAT Amount"), Text002)
                            else
                                Error(Text000, FieldCaption("VAT Amount"), Text003);

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
                        if (CurrencyFactor = VATCurrencyFactor) or (VATCurrencyFactor = 0) or (CurrencyCode = '') then
                            Validate("VAT Amount (LCY)", "Ext. VAT Amount (LCY)");

                        if AllowVATDifference and not AllowVATDifferenceOnThisTab then
                            if ParentControl = PAGE::"Service Order Statistics" then
                                Error(Text000, FieldCaption("VAT Amount"), Text002)
                            else
                                Error(Text000, FieldCaption("VAT Amount"), Text003);

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
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if MainFormActiveTab = MainFormActiveTab::Other then
            VATAmountEditable := AllowVATDifference and not "Includes Prepayment"
        else
            VATAmountEditable := AllowVATDifference;
        VATAmountLCYEditable := AllowVATDifferenceOnThisTab; // NAVCZ
        InvoiceDiscountAmountEditable := AllowInvDisc and not "Includes Prepayment";

        // NAVCZ
        if VATAmountLCYEditable then
            VATAmountLCYEditable := not UseExtAmount;
        ExtVATAmountLCYEditable :=
          AllowVATDifference and not "Includes Prepayment" and UseExtAmount;
        // NAVCZ
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

    var
        Text000: Label '%1 can only be modified on the %2 tab.';
        Text001: Label 'The total %1 for a document must not exceed the value %2 in the %3 field.';
        Currency: Record Currency;
        ServHeader: Record "Service Header";
        CurrencyCode: Code[10];
        AllowVATDifference: Boolean;
        AllowVATDifferenceOnThisTab: Boolean;
        PricesIncludingVAT: Boolean;
        AllowInvDisc: Boolean;
        VATBaseDiscPct: Decimal;
        ParentControl: Integer;
        Text002: Label 'Details';
        Text003: Label 'Invoicing';
        CurrentTabNo: Integer;
        MainFormActiveTab: Option Other,Prepayment;
        [InDataSet]
        VATAmountEditable: Boolean;
        [InDataSet]
        InvoiceDiscountAmountEditable: Boolean;
        CurrencyFactor: Decimal;
        [InDataSet]
        VATAmountLCYEditable: Boolean;
        [InDataSet]
        ExtVATAmountLCYEditable: Boolean;
        VATCurrencyFactor: Decimal;
        UseExtAmount: Boolean;

    procedure SetTempVATAmountLine(var NewVATAmountLine: Record "VAT Amount Line")
    begin
        DeleteAll();
        if NewVATAmountLine.Find('-') then
            repeat
                Copy(NewVATAmountLine);
                Insert;
            until NewVATAmountLine.Next() = 0;
        CurrPage.Update(false);
    end;

    procedure GetTempVATAmountLine(var NewVATAmountLine: Record "VAT Amount Line")
    begin
        NewVATAmountLine.DeleteAll();
        if Find('-') then
            repeat
                NewVATAmountLine.Copy(Rec);
                NewVATAmountLine.Insert();
            until Next() = 0;
    end;

    procedure InitGlobals(NewCurrencyCode: Code[10]; NewAllowVATDifference: Boolean; NewAllowVATDifferenceOnThisTab: Boolean; NewPricesIncludingVAT: Boolean; NewAllowInvDisc: Boolean; NewVATBaseDiscPct: Decimal)
    begin
        OnBeforeInitGlobals(NewCurrencyCode, NewAllowVATDifference, NewAllowVATDifferenceOnThisTab, NewPricesIncludingVAT, NewAllowInvDisc, NewVATBaseDiscPct);
        CurrencyCode := NewCurrencyCode;
        AllowVATDifference := NewAllowVATDifference;
        AllowVATDifferenceOnThisTab := NewAllowVATDifferenceOnThisTab;
        PricesIncludingVAT := NewPricesIncludingVAT;
        AllowInvDisc := NewAllowInvDisc;
        VATBaseDiscPct := NewVATBaseDiscPct;
        VATAmountEditable := AllowVATDifference;
        InvoiceDiscountAmountEditable := AllowInvDisc;
        Currency.Initialize(CurrencyCode);
        CurrPage.Update(false);
    end;

    local procedure FormCheckVATDifference()
    var
        VATAmountLine2: Record "VAT Amount Line";
        TotalVATDifference: Decimal;
    begin
        CheckVATDifference(CurrencyCode, AllowVATDifference);
        VATAmountLine2 := Rec;
        TotalVATDifference := Abs("VAT Difference") - Abs(xRec."VAT Difference");
        if Find('-') then
            repeat
                TotalVATDifference := TotalVATDifference + Abs("VAT Difference");
            until Next() = 0;
        Rec := VATAmountLine2;
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
        VATAmountLine2 := Rec;
        TotalVATDifference := Abs("VAT Difference (LCY)") - Abs(xRec."VAT Difference (LCY)");
        if Find('-') then
            repeat
                TotalVATDifference := TotalVATDifference + Abs("VAT Difference (LCY)");
            until Next() = 0;
        Rec := VATAmountLine2;
        GLSetup.Get();
        if TotalVATDifference > GLSetup."Max. VAT Difference Allowed" then
            Error(
              Text001, FieldCaption("VAT Difference (LCY)"),
              GLSetup.FieldCaption("Max. VAT Difference Allowed"), GLSetup."Max. VAT Difference Allowed");
        // NAVCZ
    end;

    local procedure ModifyRec(ModifyLCY: Boolean)
    var
        ServLine: Record "Service Line";
    begin
        Modified := true;
        Modify;
        ModifyAll("Modified (LCY)", ModifyLCY); // NAVCZ

        if ((ParentControl = PAGE::"Service Order Statistics") and
            (CurrentTabNo <> 1)) or
           (ParentControl = PAGE::"Service Statistics")
        then
            if GetAnyLineModified then begin
                ServLine.UpdateVATOnLines(0, ServHeader, ServLine, Rec);
                ServLine.UpdateVATOnLines(1, ServHeader, ServLine, Rec);
            end;
    end;

    procedure SetParentControl(ID: Integer)
    begin
        ParentControl := ID;
        OnAfterSetParentControl(ParentControl);
    end;

    procedure SetServHeader(ServiceHeader: Record "Service Header")
    begin
        ServHeader := ServiceHeader;
    end;

    procedure SetCurrentTabNo(TabNo: Integer)
    begin
        CurrentTabNo := TabNo;
    end;

    [Scope('OnPrem')]
    [Obsolete('Unsupported functionality. The function for adjusting VAT on document statistics is discontinued.', '18.0')]
    procedure SetCurrencyFactor(NewCurrencyFactor: Decimal)
    begin
        CurrencyFactor := NewCurrencyFactor; // NAVCZ
    end;

    [Scope('OnPrem')]
    [Obsolete('Unsupported functionality. The function for adjusting VAT on document statistics is discontinued.', '18.0')]
    procedure SetVATCurrencyFactor(NewVATCurrencyFactor: Decimal)
    begin
        // NAVCZ
        VATCurrencyFactor := NewVATCurrencyFactor;
        UseExtAmount := true;
        // NAVCZ
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterSetParentControl(var ParentControl: integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnBeforeInitGlobals(NewCurrencyCode: Code[10]; NewAllowVATDifference: Boolean; NewAllowVATDifferenceOnThisTab: Boolean; NewPricesIncludingVAT: Boolean; NewAllowInvDisc: Boolean; NewVATBaseDiscPct: Decimal)
    begin
    end;
}

#endif