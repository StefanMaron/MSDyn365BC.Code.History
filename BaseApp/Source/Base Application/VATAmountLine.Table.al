table 290 "VAT Amount Line"
{
    Caption = 'VAT Amount Line';

    fields
    {
        field(1; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(2; "VAT Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base';
            Editable = false;
        }
        field(3; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount';

            trigger OnValidate()
            begin
                TestField("VAT %");
                TestField("VAT Base");
                if "VAT Amount" / "VAT Base" < 0 then
                    Error(Text002, FieldCaption("VAT Amount"));
                "VAT Difference" := "VAT Amount" - "Calculated VAT Amount";
            end;
        }
        field(4; "Amount Including VAT"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;
        }
        field(5; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(6; "Line Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Line Amount';
            Editable = false;
        }
        field(7; "Inv. Disc. Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inv. Disc. Base Amount';
            Editable = false;
        }
        field(8; "Invoice Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Invoice Discount Amount';

            trigger OnValidate()
            begin
                TestField("Inv. Disc. Base Amount");
                if "Invoice Discount Amount" / "Inv. Disc. Base Amount" > 1 then
                    Error(
                      InvoiceDiscAmtIsGreaterThanBaseAmtErr,
                      FieldCaption("Invoice Discount Amount"), "Inv. Disc. Base Amount");
                "VAT Base" := CalcLineAmount;
            end;
        }
        field(9; "VAT Calculation Type"; Option)
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
            OptionCaption = 'Normal VAT,Reverse Charge VAT,Full VAT,Sales Tax';
            OptionMembers = "Normal VAT","Reverse Charge VAT","Full VAT","Sales Tax";
        }
        field(10; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            Editable = false;
            TableRelation = "Tax Group";
        }
        field(11; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(12; Modified; Boolean)
        {
            Caption = 'Modified';
        }
        field(13; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        field(14; "Calculated VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Calculated VAT Amount';
            Editable = false;
        }
        field(15; "VAT Difference"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(16; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(17; "Includes Prepayment"; Boolean)
        {
            Caption = 'Includes Prepayment';
        }
        field(18; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        field(19; "Tax Category"; Code[10])
        {
            Caption = 'Tax Category';
        }
        field(20; "Pmt. Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Pmt. Discount Amount';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "VAT Identifier", "VAT Calculation Type", "Tax Group Code", "Use Tax", Positive)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label '%1% VAT';
        Text001: Label 'VAT Amount';
        Text002: Label '%1 must not be negative.';
        InvoiceDiscAmtIsGreaterThanBaseAmtErr: Label 'The maximum %1 that you can apply is %2.', Comment = '1 Invoice Discount Amount that should be set 2 Maximum Amount that you can assign';
        Text004: Label '%1 for %2 must not exceed %3 = %4.';
        Currency: Record Currency;
        AllowVATDifference: Boolean;
        GlobalsInitialized: Boolean;
        Text005: Label '%1 must not exceed %2 = %3.';

    procedure CheckVATDifference(NewCurrencyCode: Code[10]; NewAllowVATDifference: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        InitGlobals(NewCurrencyCode, NewAllowVATDifference);
        if not AllowVATDifference then
            TestField("VAT Difference", 0);
        if Abs("VAT Difference") > Currency."Max. VAT Difference Allowed" then
            if NewCurrencyCode <> '' then
                Error(
                  Text004, FieldCaption("VAT Difference"), Currency.Code,
                  Currency.FieldCaption("Max. VAT Difference Allowed"), Currency."Max. VAT Difference Allowed")
            else begin
                if GLSetup.Get then;
                if Abs("VAT Difference") > GLSetup."Max. VAT Difference Allowed" then
                    Error(
                      Text005, FieldCaption("VAT Difference"),
                      GLSetup.FieldCaption("Max. VAT Difference Allowed"), GLSetup."Max. VAT Difference Allowed");
            end;
    end;

    local procedure InitGlobals(NewCurrencyCode: Code[10]; NewAllowVATDifference: Boolean)
    begin
        if GlobalsInitialized then
            exit;

        Currency.Initialize(NewCurrencyCode);
        AllowVATDifference := NewAllowVATDifference;
        GlobalsInitialized := true;
    end;

    procedure InsertLine(): Boolean
    var
        VATAmountLine: Record "VAT Amount Line";
    begin
        if not (("VAT Base" <> 0) or ("Amount Including VAT" <> 0)) then
            exit(false);

        Positive := "Line Amount" >= 0;
        VATAmountLine := Rec;
        if Find then begin
            "Line Amount" += VATAmountLine."Line Amount";
            "Inv. Disc. Base Amount" += VATAmountLine."Inv. Disc. Base Amount";
            "Invoice Discount Amount" += VATAmountLine."Invoice Discount Amount";
            Quantity += VATAmountLine.Quantity;
            "VAT Base" += VATAmountLine."VAT Base";
            "Amount Including VAT" += VATAmountLine."Amount Including VAT";
            "VAT Difference" += VATAmountLine."VAT Difference";
            "VAT Amount" := "Amount Including VAT" - "VAT Base";
            "Calculated VAT Amount" += VATAmountLine."Calculated VAT Amount";
            OnInsertLineOnBeforeModify(Rec, VATAmountLine);
            Modify;
        end else begin
            "VAT Amount" := "Amount Including VAT" - "VAT Base";
            Insert;
        end;

        exit(true);
    end;

    procedure InsertNewLine(VATIdentifier: Code[20]; VATCalcType: Option; TaxGroupCode: Code[20]; UseTax: Boolean; TaxRate: Decimal; IsPositive: Boolean; IsPrepayment: Boolean)
    begin
        Init;
        "VAT Identifier" := VATIdentifier;
        "VAT Calculation Type" := VATCalcType;
        "Tax Group Code" := TaxGroupCode;
        "Use Tax" := UseTax;
        "VAT %" := TaxRate;
        Modified := true;
        Positive := IsPositive;
        "Includes Prepayment" := IsPrepayment;
        Insert;
    end;

    procedure GetLine(Number: Integer)
    begin
        if Number = 1 then
            Find('-')
        else
            Next;
    end;

    procedure VATAmountText() Result: Text[30]
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        FullCount: Integer;
        VATPercentage: Decimal;
    begin
        VATPercentage := 0;
        FullCount := Count;
        if FullCount = 1 then begin
            FindFirst;
            if "VAT %" <> 0 then
                VATPercentage := "VAT %";
        end else
            if FullCount > 1 then begin
                TempVATAmountLine.Copy(Rec, true);
                TempVATAmountLine.FindFirst;
                if TempVATAmountLine."VAT %" <> 0 then begin
                    TempVATAmountLine.SetRange("VAT %", TempVATAmountLine."VAT %");
                    if TempVATAmountLine.Count = FullCount then
                        VATPercentage := TempVATAmountLine."VAT %";
                end;
            end;
        if VATPercentage = 0 then
            Result := Text001
        else
            Result := StrSubstNo(Text000, VATPercentage);
        OnAfterVATAmountText(VATPercentage, FullCount, Result);
    end;

    procedure GetTotalLineAmount(SubtractVAT: Boolean; CurrencyCode: Code[10]): Decimal
    var
        LineAmount: Decimal;
    begin
        if SubtractVAT then
            Currency.Initialize(CurrencyCode);

        LineAmount := 0;

        if Find('-') then
            repeat
                if SubtractVAT then
                    LineAmount :=
                      LineAmount + Round("Line Amount" / (1 + "VAT %" / 100), Currency."Amount Rounding Precision")
                else
                    LineAmount := LineAmount + "Line Amount";
            until Next = 0;

        exit(LineAmount);
    end;

    procedure GetTotalVATAmount(): Decimal
    begin
        CalcSums("VAT Amount");
        exit("VAT Amount");
    end;

    procedure GetTotalInvDiscAmount(): Decimal
    begin
        CalcSums("Invoice Discount Amount");
        exit("Invoice Discount Amount");
    end;

    procedure GetTotalInvDiscBaseAmount(SubtractVAT: Boolean; CurrencyCode: Code[10]): Decimal
    var
        InvDiscBaseAmount: Decimal;
    begin
        if SubtractVAT then
            Currency.Initialize(CurrencyCode);

        InvDiscBaseAmount := 0;

        if Find('-') then
            repeat
                if SubtractVAT then
                    InvDiscBaseAmount :=
                      InvDiscBaseAmount +
                      Round("Inv. Disc. Base Amount" / (1 + "VAT %" / 100), Currency."Amount Rounding Precision")
                else
                    InvDiscBaseAmount := InvDiscBaseAmount + "Inv. Disc. Base Amount";
            until Next = 0;
        exit(InvDiscBaseAmount);
    end;

    procedure GetTotalVATBase(): Decimal
    begin
        CalcSums("VAT Base");
        exit("VAT Base");
    end;

    procedure GetTotalAmountInclVAT(): Decimal
    begin
        CalcSums("Amount Including VAT");
        exit("Amount Including VAT");
    end;

    procedure GetTotalVATDiscount(CurrencyCode: Code[10]; NewPricesIncludingVAT: Boolean): Decimal
    var
        VATDiscount: Decimal;
        VATBase: Decimal;
    begin
        Currency.Initialize(CurrencyCode);

        VATDiscount := 0;

        if Find('-') then
            repeat
                if NewPricesIncludingVAT then
                    VATBase += CalcLineAmount * "VAT %" / (100 + "VAT %")
                else
                    VATBase += "VAT Base" * "VAT %" / 100;
                VATDiscount :=
                  VATDiscount +
                  Round(
                    VATBase,
                    Currency."Amount Rounding Precision", Currency.VATRoundingDirection) -
                  "VAT Amount" + "VAT Difference";
                VATBase := VATBase - Round(VATBase, Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
            until Next = 0;
        exit(VATDiscount);
    end;

    procedure GetAnyLineModified(): Boolean
    begin
        if Find('-') then
            repeat
                if Modified then
                    exit(true);
            until Next = 0;
        exit(false);
    end;

    procedure SetInvoiceDiscountAmount(NewInvoiceDiscount: Decimal; NewCurrencyCode: Code[10]; NewPricesIncludingVAT: Boolean; NewVATBaseDiscPct: Decimal)
    var
        TotalInvDiscBaseAmount: Decimal;
        NewRemainder: Decimal;
    begin
        InitGlobals(NewCurrencyCode, false);
        TotalInvDiscBaseAmount := GetTotalInvDiscBaseAmount(false, Currency.Code);
        if TotalInvDiscBaseAmount = 0 then
            exit;
        Find('-');
        repeat
            if "Inv. Disc. Base Amount" <> 0 then begin
                if TotalInvDiscBaseAmount = 0 then
                    NewRemainder := 0
                else
                    NewRemainder :=
                      NewRemainder + NewInvoiceDiscount * "Inv. Disc. Base Amount" / TotalInvDiscBaseAmount;
                if "Invoice Discount Amount" <> Round(NewRemainder, Currency."Amount Rounding Precision") then begin
                    Validate(
                      "Invoice Discount Amount", Round(NewRemainder, Currency."Amount Rounding Precision"));
                    CalcVATFields(NewCurrencyCode, NewPricesIncludingVAT, NewVATBaseDiscPct);
                    Modified := true;
                    Modify;
                end;
                NewRemainder := NewRemainder - "Invoice Discount Amount";
            end;
        until Next = 0;
    end;

    procedure SetInvoiceDiscountPercent(NewInvoiceDiscountPct: Decimal; NewCurrencyCode: Code[10]; NewPricesIncludingVAT: Boolean; CalcInvDiscPerVATID: Boolean; NewVATBaseDiscPct: Decimal)
    var
        NewRemainder: Decimal;
    begin
        InitGlobals(NewCurrencyCode, false);
        if Find('-') then
            repeat
                if "Inv. Disc. Base Amount" <> 0 then begin
                    NewRemainder :=
                      NewRemainder + NewInvoiceDiscountPct * "Inv. Disc. Base Amount" / 100;
                    if "Invoice Discount Amount" <> Round(NewRemainder, Currency."Amount Rounding Precision") then begin
                        Validate(
                          "Invoice Discount Amount", Round(NewRemainder, Currency."Amount Rounding Precision"));
                        CalcVATFields(NewCurrencyCode, NewPricesIncludingVAT, NewVATBaseDiscPct);
                        "VAT Difference" := 0;
                        Modified := true;
                        Modify;
                    end;
                    if CalcInvDiscPerVATID then
                        NewRemainder := 0
                    else
                        NewRemainder := NewRemainder - "Invoice Discount Amount";
                end;
            until Next = 0;
    end;

    local procedure GetCalculatedVAT(NewCurrencyCode: Code[10]; NewPricesIncludingVAT: Boolean; NewVATBaseDiscPct: Decimal): Decimal
    begin
        InitGlobals(NewCurrencyCode, false);

        if NewPricesIncludingVAT then
            exit(
              Round(
                CalcLineAmount * "VAT %" / (100 + "VAT %") * (1 - NewVATBaseDiscPct / 100),
                Currency."Amount Rounding Precision", Currency.VATRoundingDirection));

        exit(
          Round(
            CalcLineAmount * "VAT %" / 100 * (1 - NewVATBaseDiscPct / 100),
            Currency."Amount Rounding Precision", Currency.VATRoundingDirection));
    end;

    procedure CalcLineAmount() LineAmount: Decimal
    begin
        LineAmount := "Line Amount" - "Invoice Discount Amount";

        OnAfterCalcLineAmount(Rec, LineAmount);
    end;

    procedure CalcVATFields(NewCurrencyCode: Code[10]; NewPricesIncludingVAT: Boolean; NewVATBaseDiscPct: Decimal)
    begin
        InitGlobals(NewCurrencyCode, false);

        "VAT Amount" := GetCalculatedVAT(NewCurrencyCode, NewPricesIncludingVAT, NewVATBaseDiscPct);

        if NewPricesIncludingVAT then begin
            if NewVATBaseDiscPct = 0 then begin
                "Amount Including VAT" := CalcLineAmount;
                "VAT Base" := "Amount Including VAT" - "VAT Amount";
            end else begin
                "VAT Base" :=
                  Round(CalcLineAmount / (1 + "VAT %" / 100), Currency."Amount Rounding Precision");
                "Amount Including VAT" := "VAT Base" + "VAT Amount";
            end;
        end else begin
            "VAT Base" := CalcLineAmount;
            "Amount Including VAT" := "VAT Base" + "VAT Amount";
        end;
        "Calculated VAT Amount" := "VAT Amount";
        "VAT Difference" := 0;
        Modified := true;
    end;

    local procedure CalcValueLCY(Value: Decimal; PostingDate: Date; CurrencyCode: Code[10]; CurrencyFactor: Decimal): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        exit(CurrencyExchangeRate.ExchangeAmtFCYToLCY(PostingDate, CurrencyCode, Value, CurrencyFactor));
    end;

    procedure GetBaseLCY(PostingDate: Date; CurrencyCode: Code[10]; CurrencyFactor: Decimal): Decimal
    begin
        exit(Round(CalcValueLCY("VAT Base", PostingDate, CurrencyCode, CurrencyFactor)));
    end;

    procedure GetAmountLCY(PostingDate: Date; CurrencyCode: Code[10]; CurrencyFactor: Decimal): Decimal
    begin
        exit(
          Round(CalcValueLCY("Amount Including VAT", PostingDate, CurrencyCode, CurrencyFactor)) -
          Round(CalcValueLCY("VAT Base", PostingDate, CurrencyCode, CurrencyFactor)));
    end;

    procedure DeductVATAmountLine(var VATAmountLineDeduct: Record "VAT Amount Line")
    begin
        if FindSet then
            repeat
                VATAmountLineDeduct := Rec;
                if VATAmountLineDeduct.Find then begin
                    "VAT Base" -= VATAmountLineDeduct."VAT Base";
                    "VAT Amount" -= VATAmountLineDeduct."VAT Amount";
                    "Amount Including VAT" -= VATAmountLineDeduct."Amount Including VAT";
                    "Line Amount" -= VATAmountLineDeduct."Line Amount";
                    "Inv. Disc. Base Amount" -= VATAmountLineDeduct."Inv. Disc. Base Amount";
                    "Invoice Discount Amount" -= VATAmountLineDeduct."Invoice Discount Amount";
                    "Calculated VAT Amount" -= VATAmountLineDeduct."Calculated VAT Amount";
                    "VAT Difference" -= VATAmountLineDeduct."VAT Difference";
                    Modify;
                end;
            until Next = 0;
    end;

    procedure SumLine(LineAmount: Decimal; InvDiscAmount: Decimal; VATDifference: Decimal; AllowInvDisc: Boolean; Prepayment: Boolean)
    begin
        "Line Amount" += LineAmount;
        if AllowInvDisc then
            "Inv. Disc. Base Amount" += LineAmount;
        "Invoice Discount Amount" += InvDiscAmount;
        "VAT Difference" += VATDifference;
        if Prepayment then
            "Includes Prepayment" := true;
        Modify;
    end;

    procedure UpdateLines(var TotalVATAmount: Decimal; Currency: Record Currency; CurrencyFactor: Decimal; PricesIncludingVAT: Boolean; VATBaseDiscountPerc: Decimal; TaxAreaCode: Code[20]; TaxLiable: Boolean; PostingDate: Date)
    var
        PrevVATAmountLine: Record "VAT Amount Line";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
    begin
        if FindSet then
            repeat
                if (PrevVATAmountLine."VAT Identifier" <> "VAT Identifier") or
                   (PrevVATAmountLine."VAT Calculation Type" <> "VAT Calculation Type") or
                   (PrevVATAmountLine."Tax Group Code" <> "Tax Group Code") or
                   (PrevVATAmountLine."Use Tax" <> "Use Tax")
                then
                    PrevVATAmountLine.Init;
                if PricesIncludingVAT then
                    case "VAT Calculation Type" of
                        "VAT Calculation Type"::"Normal VAT",
                        "VAT Calculation Type"::"Reverse Charge VAT":
                            begin
                                "VAT Base" :=
                                  Round(CalcLineAmount / (1 + "VAT %" / 100), Currency."Amount Rounding Precision") - "VAT Difference";
                                "VAT Amount" :=
                                  "VAT Difference" +
                                  Round(
                                    PrevVATAmountLine."VAT Amount" +
                                    (CalcLineAmount - "VAT Base" - "VAT Difference") *
                                    (1 - VATBaseDiscountPerc / 100),
                                    Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                                "Amount Including VAT" := "VAT Base" + "VAT Amount";
                                if Positive then
                                    PrevVATAmountLine.Init
                                else begin
                                    PrevVATAmountLine := Rec;
                                    PrevVATAmountLine."VAT Amount" :=
                                      (CalcLineAmount - "VAT Base" - "VAT Difference") *
                                      (1 - VATBaseDiscountPerc / 100);
                                    PrevVATAmountLine."VAT Amount" :=
                                      PrevVATAmountLine."VAT Amount" -
                                      Round(PrevVATAmountLine."VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                                end;
                            end;
                        "VAT Calculation Type"::"Full VAT":
                            begin
                                "VAT Base" := 0;
                                "VAT Amount" := "VAT Difference" + CalcLineAmount;
                                "Amount Including VAT" := "VAT Amount";
                            end;
                        "VAT Calculation Type"::"Sales Tax":
                            begin
                                "Amount Including VAT" := CalcLineAmount;
                                if "Use Tax" then
                                    "VAT Base" := "Amount Including VAT"
                                else
                                    "VAT Base" :=
                                      Round(
                                        SalesTaxCalculate.ReverseCalculateTax(
                                          TaxAreaCode, "Tax Group Code", TaxLiable, PostingDate, "Amount Including VAT", Quantity, CurrencyFactor),
                                        Currency."Amount Rounding Precision");
                                OnAfterSalesTaxCalculateReverseCalculateTax(Rec, Currency);
                                "VAT Amount" := "VAT Difference" + "Amount Including VAT" - "VAT Base";
                                if "VAT Base" = 0 then
                                    "VAT %" := 0
                                else
                                    "VAT %" := Round(100 * "VAT Amount" / "VAT Base", 0.00001);
                            end;
                    end
                else
                    case "VAT Calculation Type" of
                        "VAT Calculation Type"::"Normal VAT",
                        "VAT Calculation Type"::"Reverse Charge VAT":
                            begin
                                "VAT Base" := CalcLineAmount;
                                "VAT Amount" :=
                                  "VAT Difference" +
                                  Round(
                                    PrevVATAmountLine."VAT Amount" +
                                    "VAT Base" * "VAT %" / 100 * (1 - VATBaseDiscountPerc / 100),
                                    Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                                "Amount Including VAT" := CalcLineAmount + "VAT Amount";
                                if Positive then
                                    PrevVATAmountLine.Init
                                else
                                    if not "Includes Prepayment" then begin
                                        PrevVATAmountLine := Rec;
                                        PrevVATAmountLine."VAT Amount" :=
                                          "VAT Base" * "VAT %" / 100 * (1 - VATBaseDiscountPerc / 100);
                                        PrevVATAmountLine."VAT Amount" :=
                                          PrevVATAmountLine."VAT Amount" -
                                          Round(PrevVATAmountLine."VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                                    end;
                            end;
                        "VAT Calculation Type"::"Full VAT":
                            begin
                                "VAT Base" := 0;
                                "VAT Amount" := "VAT Difference" + CalcLineAmount;
                                "Amount Including VAT" := "VAT Amount";
                            end;
                        "VAT Calculation Type"::"Sales Tax":
                            begin
                                "VAT Base" := CalcLineAmount;
                                if "Use Tax" then
                                    "VAT Amount" := 0
                                else
                                    "VAT Amount" :=
                                      SalesTaxCalculate.CalculateTax(
                                        TaxAreaCode, "Tax Group Code", TaxLiable, PostingDate, "VAT Base", Quantity, CurrencyFactor);
                                OnAfterSalesTaxCalculateCalculateTax(Rec, Currency);
                                if "VAT Base" = 0 then
                                    "VAT %" := 0
                                else
                                    "VAT %" := Round(100 * "VAT Amount" / "VAT Base", 0.00001);
                                "VAT Amount" :=
                                  "VAT Difference" +
                                  Round("VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                                "Amount Including VAT" := "VAT Base" + "VAT Amount";
                            end;
                    end;

                TotalVATAmount -= "VAT Amount";
                "Calculated VAT Amount" := "VAT Amount" - "VAT Difference";
                Modify;
            until Next = 0;
    end;

    procedure CopyFromPurchInvLine(PurchInvLine: Record "Purch. Inv. Line")
    begin
        "VAT Identifier" := PurchInvLine."VAT Identifier";
        "VAT Calculation Type" := PurchInvLine."VAT Calculation Type";
        "Tax Group Code" := PurchInvLine."Tax Group Code";
        "Use Tax" := PurchInvLine."Use Tax";
        "VAT %" := PurchInvLine."VAT %";
        "VAT Base" := PurchInvLine.Amount;
        "VAT Amount" := PurchInvLine."Amount Including VAT" - PurchInvLine.Amount;
        "Amount Including VAT" := PurchInvLine."Amount Including VAT";
        "Line Amount" := PurchInvLine."Line Amount";
        if PurchInvLine."Allow Invoice Disc." then
            "Inv. Disc. Base Amount" := PurchInvLine."Line Amount";
        "Invoice Discount Amount" := PurchInvLine."Inv. Discount Amount";
        Quantity := PurchInvLine."Quantity (Base)";
        "Calculated VAT Amount" :=
          PurchInvLine."Amount Including VAT" - PurchInvLine.Amount - PurchInvLine."VAT Difference";
        "VAT Difference" := PurchInvLine."VAT Difference";

        OnAfterCopyFromPurchInvLine(Rec, PurchInvLine);
    end;

    procedure CopyFromPurchCrMemoLine(PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
        "VAT Identifier" := PurchCrMemoLine."VAT Identifier";
        "VAT Calculation Type" := PurchCrMemoLine."VAT Calculation Type";
        "Tax Group Code" := PurchCrMemoLine."Tax Group Code";
        "Use Tax" := PurchCrMemoLine."Use Tax";
        "VAT %" := PurchCrMemoLine."VAT %";
        "VAT Base" := PurchCrMemoLine.Amount;
        "VAT Amount" := PurchCrMemoLine."Amount Including VAT" - PurchCrMemoLine.Amount;
        "Amount Including VAT" := PurchCrMemoLine."Amount Including VAT";
        "Line Amount" := PurchCrMemoLine."Line Amount";
        if PurchCrMemoLine."Allow Invoice Disc." then
            "Inv. Disc. Base Amount" := PurchCrMemoLine."Line Amount";
        "Invoice Discount Amount" := PurchCrMemoLine."Inv. Discount Amount";
        Quantity := PurchCrMemoLine."Quantity (Base)";
        "Calculated VAT Amount" :=
          PurchCrMemoLine."Amount Including VAT" - PurchCrMemoLine.Amount - PurchCrMemoLine."VAT Difference";
        "VAT Difference" := PurchCrMemoLine."VAT Difference";

        OnAfterCopyFromPurchCrMemoLine(Rec, PurchCrMemoLine);
    end;

    procedure CopyFromSalesInvLine(SalesInvLine: Record "Sales Invoice Line")
    begin
        "VAT Identifier" := SalesInvLine."VAT Identifier";
        "VAT Calculation Type" := SalesInvLine."VAT Calculation Type";
        "Tax Group Code" := SalesInvLine."Tax Group Code";
        "VAT %" := SalesInvLine."VAT %";
        "VAT Base" := SalesInvLine.Amount;
        "VAT Amount" := SalesInvLine."Amount Including VAT" - SalesInvLine.Amount;
        "Amount Including VAT" := SalesInvLine."Amount Including VAT";
        "Line Amount" := SalesInvLine."Line Amount";
        if SalesInvLine."Allow Invoice Disc." then
            "Inv. Disc. Base Amount" := SalesInvLine."Line Amount";
        "Invoice Discount Amount" := SalesInvLine."Inv. Discount Amount";
        Quantity := SalesInvLine."Quantity (Base)";
        "Calculated VAT Amount" :=
          SalesInvLine."Amount Including VAT" - SalesInvLine.Amount - SalesInvLine."VAT Difference";
        "VAT Difference" := SalesInvLine."VAT Difference";

        OnAfterCopyFromSalesInvLine(Rec, SalesInvLine);
    end;

    procedure CopyFromSalesCrMemoLine(SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
        "VAT Identifier" := SalesCrMemoLine."VAT Identifier";
        "VAT Calculation Type" := SalesCrMemoLine."VAT Calculation Type";
        "Tax Group Code" := SalesCrMemoLine."Tax Group Code";
        "VAT %" := SalesCrMemoLine."VAT %";
        "VAT Base" := SalesCrMemoLine.Amount;
        "VAT Amount" := SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount;
        "Amount Including VAT" := SalesCrMemoLine."Amount Including VAT";
        "Line Amount" := SalesCrMemoLine."Line Amount";
        if SalesCrMemoLine."Allow Invoice Disc." then
            "Inv. Disc. Base Amount" := SalesCrMemoLine."Line Amount";
        "Invoice Discount Amount" := SalesCrMemoLine."Inv. Discount Amount";
        Quantity := SalesCrMemoLine."Quantity (Base)";
        "Calculated VAT Amount" := SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount - SalesCrMemoLine."VAT Difference";
        "VAT Difference" := SalesCrMemoLine."VAT Difference";

        OnAfterCopyFromSalesCrMemoLine(Rec, SalesCrMemoLine);
    end;

    procedure CopyFromServInvLine(ServInvLine: Record "Service Invoice Line")
    begin
        "VAT Identifier" := ServInvLine."VAT Identifier";
        "VAT Calculation Type" := ServInvLine."VAT Calculation Type";
        "Tax Group Code" := ServInvLine."Tax Group Code";
        "VAT %" := ServInvLine."VAT %";
        "VAT Base" := ServInvLine.Amount;
        "VAT Amount" := ServInvLine."Amount Including VAT" - ServInvLine.Amount;
        "Amount Including VAT" := ServInvLine."Amount Including VAT";
        "Line Amount" := ServInvLine."Line Amount";
        if ServInvLine."Allow Invoice Disc." then
            "Inv. Disc. Base Amount" := ServInvLine."Line Amount";
        "Invoice Discount Amount" := ServInvLine."Inv. Discount Amount";
        Quantity := ServInvLine."Quantity (Base)";
        "Calculated VAT Amount" :=
          ServInvLine."Amount Including VAT" - ServInvLine.Amount - ServInvLine."VAT Difference";
        "VAT Difference" := ServInvLine."VAT Difference";

        OnAfterCopyFromServInvLine(Rec, ServInvLine);
    end;

    procedure CopyFromServCrMemoLine(ServCrMemoLine: Record "Service Cr.Memo Line")
    begin
        "VAT Identifier" := ServCrMemoLine."VAT Identifier";
        "VAT Calculation Type" := ServCrMemoLine."VAT Calculation Type";
        "Tax Group Code" := ServCrMemoLine."Tax Group Code";
        "VAT %" := ServCrMemoLine."VAT %";
        "VAT Base" := ServCrMemoLine.Amount;
        "VAT Amount" := ServCrMemoLine."Amount Including VAT" - ServCrMemoLine.Amount;
        "Amount Including VAT" := ServCrMemoLine."Amount Including VAT";
        "Line Amount" := ServCrMemoLine."Line Amount";
        if ServCrMemoLine."Allow Invoice Disc." then
            "Inv. Disc. Base Amount" := ServCrMemoLine."Line Amount";
        "Invoice Discount Amount" := ServCrMemoLine."Inv. Discount Amount";
        Quantity := ServCrMemoLine."Quantity (Base)";
        "Calculated VAT Amount" :=
          ServCrMemoLine."Amount Including VAT" - ServCrMemoLine.Amount - ServCrMemoLine."VAT Difference";
        "VAT Difference" := ServCrMemoLine."VAT Difference";

        OnAfterCopyFromServCrMemoLine(Rec, ServCrMemoLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineAmount(var VATAmountLine: Record "VAT Amount Line"; var LineAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromPurchInvLine(var VATAmountLine: Record "VAT Amount Line"; PurchInvLine: Record "Purch. Inv. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromPurchCrMemoLine(var VATAmountLine: Record "VAT Amount Line"; PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSalesInvLine(var VATAmountLine: Record "VAT Amount Line"; SalesInvoiceLine: Record "Sales Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSalesCrMemoLine(var VATAmountLine: Record "VAT Amount Line"; SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromServInvLine(var VATAmountLine: Record "VAT Amount Line"; ServiceInvoiceLine: Record "Service Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromServCrMemoLine(var VATAmountLine: Record "VAT Amount Line"; ServiceCrMemoLine: Record "Service Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateCalculateTax(var VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateReverseCalculateTax(var VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVATAmountText(VATPercentage: Decimal; FullCount: Integer; var Result: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertLineOnBeforeModify(var VATAmountLine: Record "VAT Amount Line"; FromVATAmountLine: Record "VAT Amount Line")
    begin
    end;
}

