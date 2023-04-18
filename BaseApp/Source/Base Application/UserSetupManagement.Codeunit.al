codeunit 5700 "User Setup Management"
{
    Permissions = TableData Location = r,
                  TableData "Responsibility Center" = r;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
        RespCenter: Record "Responsibility Center";
        CompanyInfo: Record "Company Information";
        UserLocation: Code[10];
        UserRespCenter: Code[10];
        SalesUserRespCenter: Code[10];
        PurchUserRespCenter: Code[10];
        ServUserRespCenter: Code[10];
        HasGotSalesUserSetup: Boolean;
        HasGotPurchUserSetup: Boolean;
        HasGotServUserSetup: Boolean;

        Text000: Label 'customer';
        Text001: Label 'vendor';
        Text002: Label 'This %1 is related to %2 %3. Your identification is setup to process from %2 %4.';
        Text003: Label 'This document will be processed in your %2.';
        AllowedPostingDateErr: Label 'The date in the %1 field must not be after the date in the %2 field.', Comment = '%1 - caption Allow Posting From, %2 - caption Allow Posting To';
        AllowedPostingDateMsg: Label 'The setup of allowed posting dates is incorrect. The date in the %1 field must not be after the date in the %2 field.', Comment = '%1 - caption Allow Posting From, %2 - caption Allow Posting To';
        OpenGLSetupActionTxt: Label 'Open the General Ledger Setup window';
        OpenUserSetupActionTxt: Label 'Open the User Setup window';
        PostingDateRangeErr: Label 'The Posting Date is not within your range of allowed posting dates.';

    procedure GetSalesFilter(): Code[10]
    begin
        exit(GetSalesFilter(UserId));
    end;

    procedure GetPurchasesFilter(): Code[10]
    begin
        exit(GetPurchasesFilter(UserId));
    end;

    procedure GetServiceFilter(): Code[10]
    begin
        exit(GetServiceFilter(UserId));
    end;

    procedure GetSalesFilter(UserCode: Code[50]) Result: Code[10]
    var
        IsHandled: Boolean;
    begin
        if not HasGotSalesUserSetup then begin
            IsHandled := false;
            OnBeforeGetSalesFilter(UserCode, UserLocation, SalesUserRespCenter, IsHandled);
            if IsHandled then
                exit(SalesUserRespCenter);

            CompanyInfo.Get();
            SalesUserRespCenter := CompanyInfo."Responsibility Center";
            UserLocation := CompanyInfo."Location Code";
            if UserSetup.Get(UserCode) and (UserCode <> '') then
                if UserSetup."Sales Resp. Ctr. Filter" <> '' then
                    SalesUserRespCenter := UserSetup."Sales Resp. Ctr. Filter";
            OnAfterGetSalesFilter(UserSetup, SalesUserRespCenter);
            HasGotSalesUserSetup := true;
        end;
        Result := SalesUserRespCenter;
        OnAfterGetSalesFilterProcedure(UserCode, Result);
    end;

    procedure GetPurchasesFilter(UserCode: Code[50]) Result: Code[10]
    begin
        if not HasGotPurchUserSetup then begin
            CompanyInfo.Get();
            PurchUserRespCenter := CompanyInfo."Responsibility Center";
            UserLocation := CompanyInfo."Location Code";
            if UserSetup.Get(UserCode) and (UserCode <> '') then
                if UserSetup."Purchase Resp. Ctr. Filter" <> '' then
                    PurchUserRespCenter := UserSetup."Purchase Resp. Ctr. Filter";
            OnAfterGetPurchFilter(UserSetup, PurchUserRespCenter);
            HasGotPurchUserSetup := true;
        end;
        Result := PurchUserRespCenter;
        OnAfterGetPurchasesFilter(UserCode, Result);
    end;

    procedure GetServiceFilter(UserCode: Code[50]) Result: Code[10]
    begin
        if not HasGotServUserSetup then begin
            CompanyInfo.Get();
            ServUserRespCenter := CompanyInfo."Responsibility Center";
            UserLocation := CompanyInfo."Location Code";
            if UserSetup.Get(UserCode) and (UserCode <> '') then
                if UserSetup."Service Resp. Ctr. Filter" <> '' then
                    ServUserRespCenter := UserSetup."Service Resp. Ctr. Filter";
            OnAfterGetServiceFilter(UserSetup, ServUserRespCenter, UserLocation);
            HasGotServUserSetup := true;
        end;
        Result := ServUserRespCenter;
        OnAfterGetServiceFilterProcedure(UserCode, Result);
    end;

    procedure GetRespCenter(DocType: Option Sales,Purchase,Service; AccRespCenter: Code[10]): Code[10]
    var
        AccType: Text[50];
        IsHandled: Boolean;
    begin
        OnBeforeGetRespCenter(DocType, AccRespCenter, IsHandled, UserRespCenter);
        if IsHandled then
            exit(UserRespCenter);

        case DocType of
            DocType::Sales:
                begin
                    AccType := Text000;
                    UserRespCenter := GetSalesFilter();
                end;
            DocType::Purchase:
                begin
                    AccType := Text001;
                    UserRespCenter := GetPurchasesFilter();
                end;
            DocType::Service:
                begin
                    AccType := Text000;
                    UserRespCenter := GetServiceFilter();
                end;
        end;
        if (AccRespCenter <> '') and
           (UserRespCenter <> '') and
           (AccRespCenter <> UserRespCenter)
        then
            Message(
              Text002 +
              Text003,
              AccType, RespCenter.TableCaption(), AccRespCenter, UserRespCenter);
        if UserRespCenter = '' then
            exit(AccRespCenter);

        exit(UserRespCenter);
    end;

    procedure CheckRespCenter(DocType: Option Sales,Purchase,Service; AccRespCenter: Code[10]): Boolean
    begin
        exit(CheckRespCenter(DocType, AccRespCenter, UserId));
    end;

    procedure CheckRespCenter(DocType: Option Sales,Purchase,Service; AccRespCenter: Code[10]; UserCode: Code[50]): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        OnBeforeCheckRespCenter2(DocType, AccRespCenter, UserCode, IsHandled, Result);
        if IsHandled then
            exit(Result);

        case DocType of
            DocType::Sales:
                UserRespCenter := GetSalesFilter(UserCode);
            DocType::Purchase:
                UserRespCenter := GetPurchasesFilter(UserCode);
            DocType::Service:
                UserRespCenter := GetServiceFilter(UserCode);
        end;
        if (UserRespCenter <> '') and
           (AccRespCenter <> UserRespCenter)
        then
            exit(false);

        exit(true);
    end;

    procedure GetLocation(DocType: Option Sales,Purchase,Service; AccLocation: Code[10]; RespCenterCode: Code[10]) LocationCode: Code[10]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetLocation(DocType, AccLocation, RespCenterCode, LocationCode, IsHandled);
        if IsHandled then
            exit(LocationCode);

        case DocType of
            DocType::Sales:
                UserRespCenter := GetSalesFilter();
            DocType::Purchase:
                UserRespCenter := GetPurchasesFilter();
            DocType::Service:
                UserRespCenter := GetServiceFilter();
        end;
        if UserRespCenter <> '' then
            RespCenterCode := UserRespCenter;
        if RespCenter.Get(RespCenterCode) then
            if RespCenter."Location Code" <> '' then
                UserLocation := RespCenter."Location Code";
        if AccLocation <> '' then
            exit(AccLocation);

        exit(UserLocation);
    end;

    procedure CheckAllowedPostingDate(PostingDate: Date)
    begin
        if not IsPostingDateValid(PostingDate) then
            Error(ErrorInfo.Create(PostingDateRangeErr, true));
    end;

    procedure TestAllowedPostingDate(PostingDate: Date; var ErrorText: Text[250]): Boolean
    begin
        if IsPostingDateValid(PostingDate) then
            exit(true);

        ErrorText := CopyStr(PostingDateRangeErr, 1, MaxStrLen(ErrorText));
        exit(false);
    end;

    procedure CheckAllowedPostingDatesRange(AllowPostingFrom: Date; AllowPostingTo: Date; NotificationType: Option Error,Notification; InvokedBy: Integer)
    begin
        CheckAllowedPostingDatesRange(
            AllowPostingFrom, AllowPostingTo, NotificationType, InvokedBy,
            UserSetup.FieldCaption("Allow Posting From"), UserSetup.FieldCaption("Allow Posting To"));
    end;

    procedure CheckAllowedPostingDatesRange(AllowPostingFrom: Date; AllowPostingTo: Date; NotificationType: Option Error,Notification; InvokedBy: Integer; AllowPostingFromCaption: Text; AllowPostingToCaption: Text)
    var
        AllowedPostingDatesNotification: Notification;
    begin
        if AllowPostingFrom <= AllowPostingTo then
            exit;

        if (AllowPostingFrom = 0D) or (AllowPostingTo = 0D) then
            exit;

        case NotificationType of
            NotificationType::Notification:
                begin
                    AllowedPostingDatesNotification.Message :=
                        StrSubstNo(AllowedPostingDateMsg, AllowPostingFromCaption, AllowPostingToCaption);
                    case InvokedBy of
                        DATABASE::"General Ledger Setup":
                            AllowedPostingDatesNotification.AddAction(OpenGLSetupActionTxt,
                              CODEUNIT::"Document Notifications", 'ShowGLSetup');
                        DATABASE::"User Setup":
                            AllowedPostingDatesNotification.AddAction(OpenUserSetupActionTxt,
                              CODEUNIT::"Document Notifications", 'ShowUserSetup');
                    end;
                    AllowedPostingDatesNotification.Send();
                    Error('');
                end;
            NotificationType::Error:
                Error(AllowedPostingDateErr, AllowPostingFromCaption, AllowPostingToCaption);
        end;
    end;

    procedure IsPostingDateValid(PostingDate: Date): Boolean
    var
        RecID: RecordID;
    begin
        exit(IsPostingDateValidWithSetup(PostingDate, RecID));
    end;

    procedure IsPostingDateValidWithSetup(PostingDate: Date; var SetupRecordID: RecordID) Result: Boolean
    var
        UserSetup: Record "User Setup";
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        IsHandled: Boolean;
    begin
        OnBeforeIsPostingDateValidWithSetup(PostingDate, Result, IsHandled, SetupRecordID);
        if IsHandled then
            exit(Result);

        if UserId <> '' then
            if UserSetup.Get(UserId) then begin
                UserSetup.CheckAllowedPostingDates(1);
                AllowPostingFrom := UserSetup."Allow Posting From";
                AllowPostingTo := UserSetup."Allow Posting To";
                SetupRecordID := UserSetup.RecordId;
            end;
        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
            GLSetup.GetRecordOnce();
            GLSetup.CheckAllowedPostingDates(1);
            AllowPostingFrom := GLSetup."Allow Posting From";
            AllowPostingTo := GLSetup."Allow Posting To";
            SetupRecordID := GLSetup.RecordId;
        end;
        if AllowPostingTo = 0D then
            AllowPostingTo := DMY2Date(31, 12, 9999);
        exit(PostingDate in [AllowPostingFrom .. AllowPostingTo]);
    end;

    procedure IsDeferralPostingDateValidWithSetup(PostingDate: Date; var SetupRecordID: RecordID) Result: Boolean
    var
        LocalUserSetup: Record "User Setup";
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        IsHandled: Boolean;
    begin
        OnBeforeIsDeferralPostingDateValidWithSetup(PostingDate, Result, IsHandled, SetupRecordID);
        if IsHandled then
            exit(Result);

        if UserId <> '' then
            if LocalUserSetup.Get(UserId) then begin
                LocalUserSetup.CheckAllowedPostingDates(1);
                AllowPostingFrom := LocalUserSetup."Allow Deferral Posting From";
                AllowPostingTo := LocalUserSetup."Allow Deferral Posting To";
                SetupRecordID := LocalUserSetup.RecordId;
            end;
        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
            GLSetup.GetRecordOnce();
            GLSetup.CheckAllowedPostingDates(1);
            AllowPostingFrom := GLSetup."Allow Deferral Posting From";
            AllowPostingTo := GLSetup."Allow Deferral Posting To";
            SetupRecordID := GLSetup.RecordId;
        end;
        if AllowPostingTo = 0D then
            AllowPostingTo := DMY2Date(31, 12, 9999);
        exit(PostingDate in [AllowPostingFrom .. AllowPostingTo]);
    end;

    procedure IsPostingDateValidWithGenJnlTemplate(PostingDate: Date; TemplateName: Code[20]): Boolean
    var
        SetupRecordID: RecordID;
    begin
        exit(IsPostingDateValidWithGenJnlTemplateWithSetup(PostingDate, TemplateName, SetupRecordID));
    end;

    procedure IsPostingDateValidWithGenJnlTemplateWithSetup(PostingDate: Date; TemplateName: Code[20]; var SetupRecordID: RecordID): Boolean
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
    begin
        if TemplateName <> '' then begin
            GLSetup.GetRecordOnce();
            if GLSetup."Journal Templ. Name Mandatory" then begin
                GenJnlTemplate.Get(TemplateName);
                AllowPostingFrom := GenJnlTemplate."Allow Posting Date From";
                AllowPostingTo := GenJnlTemplate."Allow Posting Date To";
                SetupRecordID := GenJnlTemplate.RecordId();
            end;
        end;
        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then
            exit(IsPostingDateValidWithSetup(PostingDate, SetupRecordID));

        if (PostingDate < AllowPostingFrom) or (PostingDate > AllowPostingTo) then
            exit(false);

        exit(true);
    end;

    procedure GetSalesInvoicePostingPolicy(var PostQty: Boolean; var PostAmount: Boolean)
    var
        LocalUserSetup: Record "User Setup";
    begin
        PostQty := false;
        PostAmount := false;

        if UserId <> '' then
            if LocalUserSetup.Get(UserId) then
                case LocalUserSetup."Sales Invoice Posting Policy" of
                    "Invoice Posting Policy"::Prohibited:
                        begin
                            PostQty := true;
                            PostAmount := false;
                        end;
                    "Invoice Posting Policy"::Mandatory:
                        begin
                            PostQty := true;
                            PostAmount := true;
                        end;
                end;
    end;

    procedure GetPurchaseInvoicePostingPolicy(var PostQty: Boolean; var PostAmount: Boolean)
    var
        LocalUserSetup: Record "User Setup";
    begin
        PostQty := false;
        PostAmount := false;

        if UserId <> '' then
            if LocalUserSetup.Get(UserId) then
                case LocalUserSetup."Purch. Invoice Posting Policy" of
                    "Invoice Posting Policy"::Prohibited:
                        begin
                            PostQty := true;
                            PostAmount := false;
                        end;
                    "Invoice Posting Policy"::Mandatory:
                        begin
                            PostQty := true;
                            PostAmount := true;
                        end;
                end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchFilter(var UserSetup: Record "User Setup"; var UserRespCenter: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesFilter(var UserSetup: Record "User Setup"; var UserRespCenter: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetServiceFilter(var UserSetup: Record "User Setup"; var UserRespCenter: Code[10]; var UserLocation: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesFilterProcedure(UserCode: Code[50]; Result: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchasesFilter(UserCode: Code[50]; Result: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetServiceFilterProcedure(UserCode: Code[50]; Result: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRespCenter2(DocType: Option Sales,Purchase,Service; AccRespCenter: Code[10]; UserCode: Code[50]; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLocation(DocType: Option Sales,Purchase,Service; AccLocation: Code[10]; RespCenterCode: Code[10]; var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRespCenter(DocType: Option Sales,Purchase,Service; AccRespCenter: Code[10]; var IsHandled: Boolean; var UserRespCenter: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesFilter(UserCode: Code[50]; var UserLocation: Code[10]; var UserRespCenter: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsPostingDateValidWithSetup(PostingDate: Date; var Result: Boolean; var IsHandled: Boolean; var SetupRecordID: RecordID)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsDeferralPostingDateValidWithSetup(PostingDate: Date; var Result: Boolean; var IsHandled: Boolean; var SetupRecordID: RecordID)
    begin
    end;
}

