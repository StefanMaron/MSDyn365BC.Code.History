page 2815 "Native - Coupons"
{
    Caption = 'Native - Coupons';
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "O365 Coupon Claim";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(claimId; "Claim ID")
                {
                    ApplicationArea = All;
                    Caption = 'ClaimId', Locked = true;
                }
                field(graphContactId; "Graph Contact ID")
                {
                    ApplicationArea = All;
                    Caption = 'GraphContactId', Locked = true;
                }
                field(customerId; "Customer Id")
                {
                    ApplicationArea = All;
                    Caption = 'CustomerId';
                }
                field(usage; Usage)
                {
                    ApplicationArea = All;
                    Caption = 'Usage', Locked = true;
                }
                field(offer; Offer)
                {
                    ApplicationArea = All;
                    Caption = 'Offer', Locked = true;
                }
                field(terms; Terms)
                {
                    ApplicationArea = All;
                    Caption = 'Terms', Locked = true;
                }
                field("code"; Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code', Locked = true;
                }
                field(expiration; Expiration)
                {
                    ApplicationArea = All;
                    Caption = 'Expiration', Locked = true;
                }
                field(discountValue; "Discount Value")
                {
                    ApplicationArea = All;
                    Caption = 'DiscountValue', Locked = true;
                }
                field(discountType; "Discount Type")
                {
                    ApplicationArea = All;
                    Caption = 'DiscountType', Locked = true;
                }
                field(createdDateTime; "Created DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'CreatedDateTime', Locked = true;
                }
                field(isValid; "Is Valid")
                {
                    ApplicationArea = All;
                    Caption = 'IsValid', Locked = true;
                }
                field(status; "Status Text")
                {
                    ApplicationArea = All;
                    Caption = 'Status', Locked = true;
                }
                field(amount; "Amount Text")
                {
                    ApplicationArea = All;
                    Caption = 'Amount', Locked = true;
                }
                field(isApplied; isAppliedVar)
                {
                    ApplicationArea = All;
                    Caption = 'IsApplied', Locked = true;
                    ToolTip = 'Specifies if the coupon is applied to an invoice or a quote.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields;
    end;

    var
        isAppliedVar: Boolean;

    local procedure SetCalculatedFields()
    var
        O365CouponClaimDocLink: Record "O365 Coupon Claim Doc. Link";
        O365PostedCouponClaim: Record "O365 Posted Coupon Claim";
    begin
        O365CouponClaimDocLink.SetRange("Claim ID", "Claim ID");
        O365CouponClaimDocLink.SetRange("Graph Contact ID", "Graph Contact ID");
        isAppliedVar := not O365CouponClaimDocLink.IsEmpty;
        if not isAppliedVar then begin
            O365PostedCouponClaim.SetRange("Claim ID", "Claim ID");
            O365PostedCouponClaim.SetRange("Graph Contact ID", "Graph Contact ID");
            isAppliedVar := not O365PostedCouponClaim.IsEmpty;
        end;
        if isAppliedVar then
            "Status Text" := AppliedStatusText
        else
            UpdateStatusText;
    end;
}

