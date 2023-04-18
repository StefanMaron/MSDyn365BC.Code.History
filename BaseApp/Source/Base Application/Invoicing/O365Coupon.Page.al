#if not CLEAN21
page 2165 "O365 Coupon"
{
    Caption = 'Coupon';
    DeleteAllowed = false;
    Editable = false;
    PageType = Card;
    SourceTable = "O365 Coupon Claim";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                }
                field("Status Text"; Rec."Status Text")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    StyleExpr = StatusStyleExpr;
                }
                group(Control8)
                {
                    ShowCaption = false;
                    field(OfferText; OfferText)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Offer';
                        MultiLine = true;
                    }
                }
                group(Control12)
                {
                    ShowCaption = false;
                    field(TermsText; TermsText)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Terms';
                        MultiLine = true;
                    }
                }
                group(Control3)
                {
                    ShowCaption = false;
                    Visible = "Discount Value" <> 0;
                    field("Amount Text"; Rec."Amount Text")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        ToolTip = 'Specifies the coupon amount in words.';
                    }
                    field(Expiration; Expiration)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Expiration';
                    }
                    group(Control20)
                    {
                        ShowCaption = false;
                        Visible = ExpiresInDays >= 0;
                        field(ExpiresInDays; ExpiresInDays)
                        {
                            ApplicationArea = Invoicing, Basic, Suite;
                            Caption = 'Days until expiration';
                            ToolTip = 'Specifies the number of days until this coupon expires.';
                        }
                    }
                }
                group(Control16)
                {
                    ShowCaption = false;
                    Visible = ("Discount Value" = 0) AND (ExpiresInDays >= 0);
                    field(ExpirationDate2; Expiration)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Expiration';
                    }
                    field(ExpirationInDays2; ExpiresInDays)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Days until expiration';
                        ToolTip = 'Specifies the number of days until this coupon expires.';
                    }
                }
                group(Control22)
                {
                    ShowCaption = false;
                    Visible = ("Discount Value" = 0) AND (ExpiresInDays < 0);
                    field(ExpirationDate3; Expiration)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Expiration';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(UseCoupon)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Use coupon';
                ToolTip = 'Use this coupon on the current invoice.';
                Visible = NOT "Is applied";

                trigger OnAction()
                begin
                    ApplyCoupon();
                end;
            }
            action(DoNotUseCoupon)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Do not use coupon';
                ToolTip = 'Do not use this coupon on the current invoice.';
                Visible = "Is applied";

                trigger OnAction()
                begin
                    if Unapply() then
                        CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(UseCoupon_Promoted; UseCoupon)
                {
                }
                actionref(DoNotUseCoupon_Promoted; DoNotUseCoupon)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ExpiresInDays := Expiration - WorkDate();
        UpdateStatusText();
        CalcFields("Is applied");
        OfferText := GetOffer();
        TermsText := GetTerms();
        if ExpiresInDays < 0 then
            StatusStyleExpr := 'Unfavorable';
        if "Is applied" then
            StatusStyleExpr := 'Favorable';
    end;

    var
        ExpiresInDays: Integer;
        OfferText: Text;
        TermsText: Text;
        StatusStyleExpr: Text;

    procedure ApplyCoupon()
    begin
        if Apply() then
            CurrPage.Close();
    end;
}
#endif
