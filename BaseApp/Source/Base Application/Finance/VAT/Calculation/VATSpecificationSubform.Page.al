// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Finance.Currency;
using Microsoft.Service.Document;

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
                field("VAT Identifier"; Rec."VAT Identifier")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the contents of this field from the VAT Identifier field in the VAT Posting Setup table.';
                    Visible = false;
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT percentage that was used on the sales or purchase lines with this VAT Identifier.';
                }
                field("VAT Calculation Type"; Rec."VAT Calculation Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies how VAT will be calculated for purchases or sales of items with this particular combination of VAT business posting group and VAT product posting group.';
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total amount for sales or purchase lines with a specific VAT identifier.';
                }
                field("Inv. Disc. Base Amount"; Rec."Inv. Disc. Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the invoice discount base amount.';
                    Visible = false;
                }
                field("Invoice Discount Amount"; Rec."Invoice Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Editable = InvoiceDiscountAmountEditable;
                    ToolTip = 'Specifies the invoice discount amount for a specific VAT identifier.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.CalcVATFields(CurrencyCode, PricesIncludingVAT, VATBaseDiscPct);
                        ModifyRec();
                    end;
                }
                field("VAT Base"; Rec."VAT Base")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total net amount (amount excluding VAT) for sales or purchase lines with a specific VAT Identifier.';
                }
                field("VAT Amount"; Rec."VAT Amount")
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
                                Error(Text000, Rec.FieldCaption("VAT Amount"), Text002)
                            else
                                Error(Text000, Rec.FieldCaption("VAT Amount"), Text003);

                        if PricesIncludingVAT then
                            Rec."VAT Base" := Rec."Amount Including VAT" - Rec."VAT Amount"
                        else
                            Rec."Amount Including VAT" := Rec."VAT Amount" + Rec."VAT Base";

                        FormCheckVATDifference();
                        ModifyRec();
                    end;
                }
                field("Calculated VAT Amount"; Rec."Calculated VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the calculated VAT amount and is only used for reference when the user changes the VAT Amount manually.';
                    Visible = false;
                }
                field("VAT Difference"; Rec."VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the difference between the calculated VAT amount and a VAT amount that you have entered manually.';
                    Visible = false;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the net amount, including VAT, for this line.';

                    trigger OnValidate()
                    begin
                        FormCheckVATDifference();
                    end;
                }
                field(NonDeductibleBase; Rec."Non-Deductible VAT Base")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the amount of the transaction for which VAT is not applied due to the type of goods or services purchased.';
                    Visible = NonDeductibleVATVisible;
                }
                field(CalcNonDedVATAmount; Rec."Calc. Non-Ded. VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the calculated Non-Deductible VAT amount and is only used for reference when the user changes the Non-Deductible VAT Amount manually.';
                    Visible = false;
                }
                field(NonDeductibleAmount; Rec."Non-Deductible VAT Amount")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the amount of VAT that is not deducted due to the type of goods or services purchased.';
                    Visible = NonDeductibleVATVisible;
                    Editable = VATAmountEditable;

                    trigger OnValidate()
                    begin
                        if AllowVATDifference and not AllowVATDifferenceOnThisTab then
                            if ParentControl = PAGE::"Service Order Statistics" then
                                Error(Text000, Rec.FieldCaption("Non-Deductible VAT Amount"), Text002)
                            else
                                Error(Text000, Rec.FieldCaption("Non-Deductible VAT Amount"), Text003);
                        NonDeductibleVAT.CheckNonDeductibleVATAmountDiff(Rec, xRec, AllowVATDifference, Currency);
                        ModifyRec();
                    end;
                }
                field(DeductibleBase; Rec."Deductible VAT Base")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the amount of the transaction for which VAT is applied due to the type of goods or services purchased.';
                    Visible = NonDeductibleVATVisible;
                }
                field(DeductibleAmount; Rec."Deductible VAT Amount")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the amount of VAT that is deducted due to the type of goods or services purchased.';
                    Visible = NonDeductibleVATVisible;
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
            VATAmountEditable := AllowVATDifference and not Rec."Includes Prepayment"
        else
            VATAmountEditable := AllowVATDifference;
        InvoiceDiscountAmountEditable := AllowInvDisc and not Rec."Includes Prepayment";
    end;

    trigger OnInit()
    begin
        InvoiceDiscountAmountEditable := true;
        VATAmountEditable := true;
        NonDeductibleVATVisible := NonDeductibleVAT.IsNonDeductibleVATEnabled();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        ModifyRec();
        exit(false);
    end;

    var
        Currency: Record Currency;
        ServHeader: Record "Service Header";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        CurrencyCode: Code[10];
        AllowVATDifference: Boolean;
        AllowVATDifferenceOnThisTab: Boolean;
        PricesIncludingVAT: Boolean;
        VATBaseDiscPct: Decimal;
        ParentControl: Integer;
        CurrentTabNo: Integer;
        MainFormActiveTab: Option Other,Prepayment;
        VATAmountEditable: Boolean;
        NonDeductibleVATVisible: Boolean;

        Text000: Label '%1 can only be modified on the %2 tab.';
        Text001: Label 'The total %1 for a document must not exceed the value %2 in the %3 field.';
        Text002: Label 'Details';
        Text003: Label 'Invoicing';

    protected var
        AllowInvDisc, InvoiceDiscountAmountEditable : Boolean;

    procedure SetTempVATAmountLine(var NewVATAmountLine: Record "VAT Amount Line")
    begin
        Rec.DeleteAll();
        if NewVATAmountLine.Find('-') then
            repeat
                Rec.Copy(NewVATAmountLine);
                Rec.Insert();
            until NewVATAmountLine.Next() = 0;
        CurrPage.Update(false);
    end;

    procedure GetTempVATAmountLine(var NewVATAmountLine: Record "VAT Amount Line")
    begin
        NewVATAmountLine.DeleteAll();
        if Rec.Find('-') then
            repeat
                NewVATAmountLine.Copy(Rec);
                NewVATAmountLine.Insert();
            until Rec.Next() = 0;
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
        Rec.CheckVATDifference(CurrencyCode, AllowVATDifference);
        VATAmountLine2 := Rec;
        TotalVATDifference := Abs(Rec."VAT Difference") - Abs(xRec."VAT Difference");
        if Rec.Find('-') then
            repeat
                TotalVATDifference := TotalVATDifference + Abs(Rec."VAT Difference");
            until Rec.Next() = 0;
        Rec := VATAmountLine2;
        if TotalVATDifference > Currency."Max. VAT Difference Allowed" then
            Error(
              Text001, Rec.FieldCaption("VAT Difference"),
              Currency."Max. VAT Difference Allowed", Currency.FieldCaption("Max. VAT Difference Allowed"));
    end;

    local procedure ModifyRec()
    var
        ServLine: Record "Service Line";
    begin
        Rec.Modified := true;
        Rec.Modify();

        if ((ParentControl = PAGE::"Service Order Statistics") and
            (CurrentTabNo <> 1))
        then
            if Rec.GetAnyLineModified() then begin
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

    [IntegrationEvent(false, false)]
    procedure OnAfterSetParentControl(var ParentControl: integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnBeforeInitGlobals(NewCurrencyCode: Code[10]; NewAllowVATDifference: Boolean; NewAllowVATDifferenceOnThisTab: Boolean; NewPricesIncludingVAT: Boolean; NewAllowInvDisc: Boolean; NewVATBaseDiscPct: Decimal)
    begin
    end;
}

