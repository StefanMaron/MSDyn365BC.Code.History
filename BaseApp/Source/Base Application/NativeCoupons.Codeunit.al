#if not CLEAN20
codeunit 2815 "Native - Coupons"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
    end;

    var
        CouponDoesntExistErr: Label 'The coupon with "claimId" : "%1"  doesn''t exist for this Customer.', Comment = '%1=claimId value;%2=graphContactId value.';
        CouponAlreadyAppliedErr: Label 'The coupon is already applied in another invoice.';
        CouponInvalidErr: Label 'The status on the coupon is not valid.';

    procedure CheckIfCouponCanBeUsed(O365CouponClaimDocLink: Record "O365 Coupon Claim Doc. Link")
    var
        O365CouponClaim: Record "O365 Coupon Claim";
        O365PostedCouponClaim: Record "O365 Posted Coupon Claim";
    begin
        O365CouponClaim.Get(O365CouponClaimDocLink."Claim ID", O365CouponClaimDocLink."Graph Contact ID");

        if not O365CouponClaim."Is Valid" then
            Error(CouponInvalidErr);

        if O365CouponClaim.Usage = O365CouponClaim.Usage::oneTime then begin
            O365PostedCouponClaim.SetRange("Claim ID", O365CouponClaimDocLink."Claim ID");
            O365PostedCouponClaim.SetRange("Graph Contact ID", O365CouponClaimDocLink."Graph Contact ID");
            if not O365PostedCouponClaim.IsEmpty() then
                Error(CouponAlreadyAppliedErr);
        end;
    end;

    procedure CheckThatCouponCanBeAppliedToInvoice(O365CouponClaimDocLink: Record "O365 Coupon Claim Doc. Link")
    var
        DummySalesHeader: Record "Sales Header";
        O365CouponClaim: Record "O365 Coupon Claim";
    begin
        if (O365CouponClaimDocLink."Document Type" <> DummySalesHeader."Document Type"::Invoice) and
           (O365CouponClaimDocLink."Document Type" <> DummySalesHeader."Document Type"::Quote)
        then
            exit;

        if not O365CouponClaim.Get(O365CouponClaimDocLink."Claim ID", O365CouponClaimDocLink."Graph Contact ID") then
            Error(CouponDoesntExistErr, O365CouponClaimDocLink."Claim ID", O365CouponClaimDocLink."Graph Contact ID");
    end;

    procedure WriteCouponsJSON(DocumentType: Option; DocumentNo: Code[20]; Posted: Boolean): Text
    var
        NativeEDMTypes: Codeunit "Native - EDM Types";
    begin
        if Posted then
            exit(NativeEDMTypes.WritePostedCouponsJSON(DocumentNo));

        exit(NativeEDMTypes.WriteCouponsJSON(DocumentType, DocumentNo));
    end;
}
#endif
