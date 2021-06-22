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
                        ModifyRec;
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

                        FormCheckVATDifference;
                        ModifyRec;
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
        InvoiceDiscountAmountEditable := AllowInvDisc and not "Includes Prepayment";
    end;

    trigger OnInit()
    begin
        InvoiceDiscountAmountEditable := true;
        VATAmountEditable := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        ModifyRec;
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

    procedure SetTempVATAmountLine(var NewVATAmountLine: Record "VAT Amount Line")
    begin
        DeleteAll();
        if NewVATAmountLine.Find('-') then
            repeat
                Copy(NewVATAmountLine);
                Insert;
            until NewVATAmountLine.Next = 0;
        CurrPage.Update(false);
    end;

    procedure GetTempVATAmountLine(var NewVATAmountLine: Record "VAT Amount Line")
    begin
        NewVATAmountLine.DeleteAll();
        if Find('-') then
            repeat
                NewVATAmountLine.Copy(Rec);
                NewVATAmountLine.Insert();
            until Next = 0;
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
            until Next = 0;
        Rec := VATAmountLine2;
        if TotalVATDifference > Currency."Max. VAT Difference Allowed" then
            Error(
              Text001, FieldCaption("VAT Difference"),
              Currency."Max. VAT Difference Allowed", Currency.FieldCaption("Max. VAT Difference Allowed"));
    end;

    local procedure ModifyRec()
    var
        ServLine: Record "Service Line";
    begin
        Modified := true;
        Modify;

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
    end;

    procedure SetServHeader(ServiceHeader: Record "Service Header")
    begin
        ServHeader := ServiceHeader;
    end;

    procedure SetCurrentTabNo(TabNo: Integer)
    begin
        CurrentTabNo := TabNo;
    end;
}

