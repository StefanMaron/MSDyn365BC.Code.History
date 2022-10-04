table 2115 "O365 Coupon Claim"
{
    Caption = 'O365 Coupon Claim';
    Permissions = TableData "O365 Posted Coupon Claim" = imd;
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
#if CLEAN21
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#else
    DrillDownPageID = "O365 Coupon";
    LookupPageID = "O365 Coupon";
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; "Claim ID"; Text[150])
        {
            Caption = 'Claim ID';
        }
        field(2; "Graph Contact ID"; Text[250])
        {
            Caption = 'Graph Contact ID';
#if not CLEAN21
            trigger OnValidate()
            begin
                UpdateCustomerId();
            end;
#endif
        }
        field(3; Usage; Option)
        {
            Caption = 'Usage';
            OptionCaption = 'oneTime,multiUse';
            OptionMembers = oneTime,multiUse;
        }
        field(4; Offer; Text[250])
        {
            Caption = 'Offer';
        }
        field(5; Terms; Text[250])
        {
            Caption = 'Terms';
        }
        field(6; "Code"; Text[30])
        {
            Caption = 'Code';
        }
        field(7; Expiration; Date)
        {
            Caption = 'Expiration';
        }
        field(8; "Discount Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Discount Value';
#if not CLEAN21
            trigger OnValidate()
            begin
                UpdateAmountText();
            end;
#endif
        }
        field(9; "Discount Type"; Option)
        {
            Caption = 'Discount Type';
            OptionCaption = 'Custom,%,Amount';
            OptionMembers = Custom,"%",Amount;
#if not CLEAN21
            trigger OnValidate()
            begin
                UpdateAmountText();
            end;
#endif            
        }
        field(10; "Created DateTime"; DateTime)
        {
            Caption = 'Created DateTime';
        }
        field(11; "Is Valid"; Boolean)
        {
            Caption = 'Is Valid';
        }
        field(12; "Status Text"; Text[50])
        {
            Caption = 'Status';
        }
        field(13; "Amount Text"; Text[30])
        {
            Caption = 'Discount';
        }
        field(14; "Is applied"; Boolean)
        {
            CalcFormula = Exist("O365 Coupon Claim Doc. Link" WHERE("Claim ID" = FIELD("Claim ID"),
                                                                     "Document Type" = FIELD("Document Type Filter"),
                                                                     "Document No." = FIELD("Document No. Filter"),
                                                                     "Graph Contact ID" = FIELD("Graph Contact ID")));
            Caption = 'Is applied';
            FieldClass = FlowField;
        }
        field(15; "Document Type Filter"; Option)
        {
            Caption = 'Document Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
            TableRelation = "Sales Header"."Document Type";
        }
        field(16; "Document No. Filter"; Code[20])
        {
            Caption = 'Document No. Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Header"."No.";
        }
        field(17; "Offer Blob"; BLOB)
        {
            Caption = 'Offer Blob';
        }
        field(18; "Terms Blob"; BLOB)
        {
            Caption = 'Terms Blob';
        }
        field(8001; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
        }
        field(8002; "Customer Id"; Guid)
        {
            Caption = 'Customer Id';
            TableRelation = Customer.SystemId;
        }
    }

    keys
    {
        key(Key1; "Claim ID", "Graph Contact ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Status Text", "Code", "Amount Text", Offer)
        {
        }
    }
#if not CLEAN21
    trigger OnInsert()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnRename()
    begin
        SetLastModifiedDateTime();
    end;

    var
        O365Discounts: Codeunit "O365 Discounts";
        AppliedTxt: Label 'Applied';
        ClaimedTxt: Label 'Claimed';
        ExpiresTodayTxt: Label 'Expires today';
        ExpiresTomorrowTxt: Label 'Expires tomorrow';
        ExpiresInTxt: Label 'Expires in %1 days', Comment = '%1 = a number of days, larger than 2, ex. 5';
        ExpiredTxt: Label 'Expired';
        MustApplyDiscountManuallyMsg: Label 'You must apply this discount manually.';
        CouponHasAlreadyBeenAppliedErr: Label 'This coupon has already been applied.';
        MustUnapplyDiscountManuallyMsg: Label 'You must unapply this discount manually.';
        UnapplyDiscountPercentageOptionStringTxt: Label 'Clear invoice discount,Let me change discount';
        PercentDiscountTxt: Label '%1% off', Comment = '%1 = a number indicating the discount value, ex. 8';
        AmountDiscountTxt: Label '%1%2 off', Comment = '%1 = currency symbol, ex. $. %2 = a number indicating the discount value, ex. 8';
        CouponAlreadyUsedOnInvoiceErr: Label 'This coupon has already been applied to invoice %1. Remove it there, and then use it here.', Comment = '%1 = document no.';
        CouponAlreadyUsedOnEstimateErr: Label 'This coupon has already been applied to estimate %1. Remove it there, and then use it here.', Comment = '%1 = document no.';
        NoCouponsTxt: Label 'You have one or more coupons that you can apply.';

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure GetAppliedClaimsForSalesDocument(SalesHeader: Record "Sales Header") CouponCodes: Text
    begin
        SetRange("Document Type Filter", SalesHeader."Document Type");
        SetRange("Document No. Filter", SalesHeader."No.");
        SetRange("Is applied", true);
        if not FindSet() then
            exit(NoCouponsTxt);

        UpdateAmountText();
        if Code <> '' then
            CouponCodes := Code
        else
            CouponCodes := "Amount Text";
        if Next() <> 0 then
            repeat
                CouponCodes += StrSubstNo(', %1', GetCouponPseudoCode());
            until Next() = 0;
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure GetOffer(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Offer Blob");
        if not "Offer Blob".HasValue() then
            exit(Offer);
        "Offer Blob".CreateInStream(InStream, TEXTENCODING::Windows);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure SetOffer(NewOffer: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Offer Blob");
        Offer := CopyStr(NewOffer, 1, MaxStrLen(Offer));
        if StrLen(NewOffer) <= MaxStrLen(Offer) then
            exit; // No need to store anything in the blob
        if NewOffer = '' then
            exit;

        "Offer Blob".CreateOutStream(OutStream, TEXTENCODING::Windows);
        OutStream.WriteText(NewOffer);
        Modify();
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure GetTerms(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Terms Blob");
        if not "Terms Blob".HasValue() then
            exit(Terms);
        "Terms Blob".CreateInStream(InStream, TEXTENCODING::Windows);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure SetTerms(NewTerms: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Terms Blob");
        Terms := CopyStr(NewTerms, 1, MaxStrLen(Terms));
        if StrLen(NewTerms) <= MaxStrLen(Terms) then
            exit; // No need to store anything in the blob
        if NewTerms = '' then
            exit;
        "Offer Blob".CreateOutStream(OutStream, TEXTENCODING::Windows);
        OutStream.WriteText(NewTerms);
        Modify();
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure GetCouponPseudoCode(): Text
    begin
        if Code <> '' then
            exit(Code);

        UpdateAmountText();
        exit("Amount Text");
    end;

    local procedure UpdateAmountText()
    var
        Currency: Record Currency;
    begin
        Clear("Amount Text");
        if "Discount Value" = 0 then
            exit;

        if "Discount Type" = "Discount Type"::"%" then
            "Amount Text" := StrSubstNo(PercentDiscountTxt, "Discount Value");

        if "Discount Type" = "Discount Type"::Amount then
            "Amount Text" := StrSubstNo(AmountDiscountTxt, Currency.ResolveGLCurrencySymbol(''), "Discount Value");
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure UpdateStatusText()
    begin
        "Status Text" := GetStatusText();
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure Apply(): Boolean
    var
        O365CouponClaimDocLink: Record "O365 Coupon Claim Doc. Link";
        SalesHeader: Record "Sales Header";
        O365SalesInvoiceDiscount: Page "O365 Sales Invoice Discount";
    begin
        if "Is applied" then
            exit;

        if not SalesHeader.Get(GetRangeMin("Document Type Filter"), GetRangeMin("Document No. Filter")) then
            exit;

        if Usage = Usage::oneTime then begin
            O365CouponClaimDocLink.SetRange("Claim ID", "Claim ID");
            O365CouponClaimDocLink.SetRange("Graph Contact ID", "Graph Contact ID");
            if O365CouponClaimDocLink.FindFirst() then begin
                if O365CouponClaimDocLink."Document Type" = O365CouponClaimDocLink."Document Type"::Invoice then
                    Error(CouponAlreadyUsedOnInvoiceErr, O365CouponClaimDocLink."Document No.");
                Error(CouponAlreadyUsedOnEstimateErr, O365CouponClaimDocLink."Document No.");
            end;
        end;

        if ("Discount Value" > 0) and
           ("Discount Type" = "Discount Type"::"%") and (SalesHeader."Invoice Discount Value" = 0)
        then begin
            O365SalesInvoiceDiscount.SetRecord(SalesHeader);
            O365SalesInvoiceDiscount.SetInitialDiscountPercentage("Discount Value");
            O365SalesInvoiceDiscount.LookupMode := true;
            if O365SalesInvoiceDiscount.RunModal() <> ACTION::LookupOK then
                exit;
        end else begin
            Message(MustApplyDiscountManuallyMsg);
            if PAGE.RunModal(PAGE::"O365 Sales Invoice Discount", SalesHeader) <> ACTION::LookupOK then
                exit; // The user did not apply any discount
        end;

        O365CouponClaimDocLink."Claim ID" := "Claim ID";
        O365CouponClaimDocLink."Graph Contact ID" := "Graph Contact ID";
        O365CouponClaimDocLink."Document Type" := "Sales Document Type".FromInteger(GetRangeMin("Document Type Filter"));
        O365CouponClaimDocLink."Document No." := GetRangeMin("Document No. Filter");
        if not O365CouponClaimDocLink.Insert() then
            Error(CouponHasAlreadyBeenAppliedErr);
        exit(true);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure Unapply(): Boolean
    var
        O365CouponClaimDocLink: Record "O365 Coupon Claim Doc. Link";
        SalesHeader: Record "Sales Header";
        Choice: Integer;
        OptionString: Text;
    begin
        if not O365CouponClaimDocLink.Get(
             "Claim ID", "Graph Contact ID", GetRangeMin("Document Type Filter"), GetRangeMin("Document No. Filter"))
        then
            exit;

        if not SalesHeader.Get(GetRangeMin("Document Type Filter"), GetRangeMin("Document No. Filter")) then
            exit;

        if ("Discount Value" > 0) and ("Discount Type" = "Discount Type"::"%") then begin
            OptionString := UnapplyDiscountPercentageOptionStringTxt;
            Choice := StrMenu(OptionString);
            case Choice of
                0:
                    exit(false); // Cancel
                1:
                    O365Discounts.ApplyInvoiceDiscountPercentage(SalesHeader, 0);
                2:
                    if PAGE.RunModal(PAGE::"O365 Sales Invoice Discount", SalesHeader) <> ACTION::LookupOK then
                        exit; // The user did not unapply any discount;
            end;
        end else begin
            Message(MustUnapplyDiscountManuallyMsg);
            if PAGE.RunModal(PAGE::"O365 Sales Invoice Discount", SalesHeader) <> ACTION::LookupOK then
                exit; // The user did not apply any discount
        end;

        O365CouponClaimDocLink.Delete();
        exit(true);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure RedeemCouponsForSalesDocument(PostedSalesHeader: Record "Sales Header")
    begin
        if PostedSalesHeader."No." <> '' then
            exit;
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure RedeemCoupon(CustomerNo: Code[20])
    begin
        if CustomerNo <> '' then
            exit;
    end;

    local procedure GetStatusText(): Text[50]
    var
        DaysUntilExpiration: Integer;
    begin
        CalcFields("Is applied");
        if "Is applied" then
            exit(AppliedTxt);

        if not "Is Valid" then
            exit(ClaimedTxt);

        DaysUntilExpiration := Expiration - WorkDate();

        if DaysUntilExpiration < 0 then
            exit(ExpiredTxt);

        if DaysUntilExpiration = 0 then
            exit(ExpiresTodayTxt);

        if DaysUntilExpiration = 1 then
            exit(ExpiresTomorrowTxt);

        exit(StrSubstNo(ExpiresInTxt, DaysUntilExpiration));
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure AppliedStatusText(): Text[50]
    begin
        exit(AppliedTxt);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure CouponsExistForCustomer(CustomerNo: Code[20]): Boolean
    begin
        exit(false);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure UpdateCustomerId()
    begin
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified DateTime" := CurrentDateTime;
    end;
#endif
}

