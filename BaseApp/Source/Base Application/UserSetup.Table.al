table 91 "User Setup"
{
    Caption = 'User Setup';
    DrillDownPageID = "User Setup";
    LookupPageID = "User Setup";
    ReplicateData = true;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(2; "Allow Posting From"; Date)
        {
            Caption = 'Allow Posting From';

            trigger OnValidate()
            begin
                CheckAllowedPostingDates(0);
            end;
        }
        field(3; "Allow Posting To"; Date)
        {
            Caption = 'Allow Posting To';

            trigger OnValidate()
            begin
                CheckAllowedPostingDates(0);
            end;
        }
        field(4; "Register Time"; Boolean)
        {
            Caption = 'Register Time';
        }
        field(10; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            var
                UserSetup: Record "User Setup";
            begin
                if "Salespers./Purch. Code" <> '' then begin
                    ValidateSalesPersonPurchOnUserSetup(Rec);
                    UserSetup.SetCurrentKey("Salespers./Purch. Code");
                    UserSetup.SetRange("Salespers./Purch. Code", "Salespers./Purch. Code");
                    if UserSetup.FindFirst then
                        Error(Text001, "Salespers./Purch. Code", UserSetup."User ID");
                    UpdateSalesPerson(FieldNo("Salespers./Purch. Code"));
                end;
            end;
        }
        field(11; "Approver ID"; Code[50])
        {
            Caption = 'Approver ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup"."User ID";

            trigger OnLookup()
            var
                UserSetup: Record "User Setup";
            begin
                UserSetup.SetFilter("User ID", '<>%1', "User ID");
                if PAGE.RunModal(PAGE::"Approval User Setup", UserSetup) = ACTION::LookupOK then
                    Validate("Approver ID", UserSetup."User ID");
            end;

            trigger OnValidate()
            begin
                if "Approver ID" = "User ID" then
                    FieldError("Approver ID");
            end;
        }
        field(12; "Sales Amount Approval Limit"; Integer)
        {
            BlankZero = true;
            Caption = 'Sales Amount Approval Limit';

            trigger OnValidate()
            begin
                if "Unlimited Sales Approval" and ("Sales Amount Approval Limit" <> 0) then
                    Error(Text003, FieldCaption("Sales Amount Approval Limit"), FieldCaption("Unlimited Sales Approval"));
                if "Sales Amount Approval Limit" < 0 then
                    Error(Text005);
            end;
        }
        field(13; "Purchase Amount Approval Limit"; Integer)
        {
            BlankZero = true;
            Caption = 'Purchase Amount Approval Limit';

            trigger OnValidate()
            begin
                if "Unlimited Purchase Approval" and ("Purchase Amount Approval Limit" <> 0) then
                    Error(Text003, FieldCaption("Purchase Amount Approval Limit"), FieldCaption("Unlimited Purchase Approval"));
                if "Purchase Amount Approval Limit" < 0 then
                    Error(Text005);
            end;
        }
        field(14; "Unlimited Sales Approval"; Boolean)
        {
            Caption = 'Unlimited Sales Approval';

            trigger OnValidate()
            begin
                if "Unlimited Sales Approval" then
                    "Sales Amount Approval Limit" := 0;
            end;
        }
        field(15; "Unlimited Purchase Approval"; Boolean)
        {
            Caption = 'Unlimited Purchase Approval';

            trigger OnValidate()
            begin
                if "Unlimited Purchase Approval" then
                    "Purchase Amount Approval Limit" := 0;
            end;
        }
        field(16; Substitute; Code[50])
        {
            Caption = 'Substitute';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup"."User ID";

            trigger OnLookup()
            var
                UserSetup: Record "User Setup";
            begin
                UserSetup.SetFilter("User ID", '<>%1', "User ID");
                if PAGE.RunModal(PAGE::"Approval User Setup", UserSetup) = ACTION::LookupOK then
                    Validate(Substitute, UserSetup."User ID");
            end;

            trigger OnValidate()
            begin
                if Substitute = "User ID" then
                    FieldError(Substitute);
            end;
        }
        field(17; "E-Mail"; Text[100])
        {
            Caption = 'E-Mail';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                UpdateSalesPerson(FieldNo("E-Mail"));
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        field(18; "Phone No."; text[30])
        {
            Caption = 'Phone No.';
            DataClassification = CustomerContent;
            ExtendedDatatype = PhoneNo;

            trigger OnValidate()
            var
                Char: DotNet Char;
                i: Integer;
            begin
                for i := 1 to StrLen("Phone No.") do
                    if Char.IsLetter("Phone No."[i]) then
                        FieldError("Phone No.", PhoneNoCannotContainLettersErr);

                UpdateSalesPerson(FieldNo("Phone No."));
            end;
        }
        field(19; "Request Amount Approval Limit"; Integer)
        {
            BlankZero = true;
            Caption = 'Request Amount Approval Limit';

            trigger OnValidate()
            begin
                if "Unlimited Request Approval" and ("Request Amount Approval Limit" <> 0) then
                    Error(Text003, FieldCaption("Request Amount Approval Limit"), FieldCaption("Unlimited Request Approval"));
                if "Request Amount Approval Limit" < 0 then
                    Error(Text005);
            end;
        }
        field(20; "Unlimited Request Approval"; Boolean)
        {
            Caption = 'Unlimited Request Approval';

            trigger OnValidate()
            begin
                if "Unlimited Request Approval" then
                    "Request Amount Approval Limit" := 0;
            end;
        }
        field(21; "Approval Administrator"; Boolean)
        {
            Caption = 'Approval Administrator';

            trigger OnValidate()
            var
                UserSetup: Record "User Setup";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateApprovalAdministrator(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Approval Administrator" then begin
                    UserSetup.SetRange("Approval Administrator", true);
                    if not UserSetup.IsEmpty then
                        FieldError("Approval Administrator");
                end;
            end;
        }
        field(31; "License Type"; Option)
        {
            CalcFormula = Lookup(User."License Type" WHERE("User Name" = FIELD("User ID")));
            Caption = 'License Type';
            FieldClass = FlowField;
            OptionCaption = 'Full User,Limited User,Device Only User,Windows Group,External User';
            OptionMembers = "Full User","Limited User","Device Only User","Windows Group","External User";
        }
        field(950; "Time Sheet Admin."; Boolean)
        {
            Caption = 'Time Sheet Admin.';
        }
        field(5600; "Allow FA Posting From"; Date)
        {
            Caption = 'Allow FA Posting From';
        }
        field(5601; "Allow FA Posting To"; Date)
        {
            Caption = 'Allow FA Posting To';
        }
        field(5700; "Sales Resp. Ctr. Filter"; Code[10])
        {
            Caption = 'Sales Resp. Ctr. Filter';
            TableRelation = "Responsibility Center".Code;
        }
        field(5701; "Purchase Resp. Ctr. Filter"; Code[10])
        {
            Caption = 'Purchase Resp. Ctr. Filter';
            TableRelation = "Responsibility Center";
        }
        field(5900; "Service Resp. Ctr. Filter"; Code[10])
        {
            Caption = 'Service Resp. Ctr. Filter';
            TableRelation = "Responsibility Center";
        }
        field(11700; "Check Payment Orders"; Boolean)
        {
            Caption = 'Check Payment Orders';
        }
        field(11701; "Check Bank Statements"; Boolean)
        {
            Caption = 'Check Bank Statements';
        }
        field(11730; "Cash Resp. Ctr. Filter"; Code[10])
        {
            Caption = 'Cash Resp. Ctr. Filter';
            TableRelation = "Responsibility Center";
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11760; "Check Document Date(work date)"; Boolean)
        {
            Caption = 'Check Document Date(work date)';
        }
        field(11761; "Check Document Date(sys. date)"; Boolean)
        {
            Caption = 'Check Document Date(sys. date)';
        }
        field(11762; "Check Posting Date (work date)"; Boolean)
        {
            Caption = 'Check Posting Date (work date)';
        }
        field(11763; "Check Posting Date (sys. date)"; Boolean)
        {
            Caption = 'Check Posting Date (sys. date)';
        }
        field(11764; "Check Bank Accounts"; Boolean)
        {
            Caption = 'Check Bank Accounts';
        }
        field(11765; "Check Journal Templates"; Boolean)
        {
            Caption = 'Check Journal Templates';
        }
        field(11766; "Check Dimension Values"; Boolean)
        {
            Caption = 'Check Dimension Values';
        }
        field(11767; "Allow Posting to Closed Period"; Boolean)
        {
            Caption = 'Allow Posting to Closed Period';
        }
        field(11768; "Allow VAT Posting From"; Date)
        {
            Caption = 'Allow VAT Posting From';
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11769; "Allow VAT Posting To"; Date)
        {
            Caption = 'Allow VAT Posting To';
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11790; "Allow Complete Job"; Boolean)
        {
            Caption = 'Allow Complete Job';
        }
        field(11791; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(11792; "User Name"; Text[50])
        {
            Caption = 'User Name';
        }
        field(31070; "Allow Item Unapply"; Boolean)
        {
            Caption = 'Allow Item Unapply';
        }
        field(31071; "Check Location Code"; Boolean)
        {
            Caption = 'Check Location Code';
        }
        field(31072; "Check Release Location Code"; Boolean)
        {
            Caption = 'Check Release Location Code';
        }
        field(31073; "Check Whse. Net Change Temp."; Boolean)
        {
            Caption = 'Check Whse. Net Change Temp.';
        }
        field(31110; "Bank Amount Approval Limit"; Integer)
        {
            BlankZero = true;
            Caption = 'Bank Amount Approval Limit';
        }
        field(31111; "Unlimited Bank Approval"; Boolean)
        {
            Caption = 'Unlimited Bank Approval';
        }
        field(31112; "Cash Desk Amt. Approval Limit"; Integer)
        {
            BlankZero = true;
            Caption = 'Cash Desk Amt. Approval Limit';
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
            ObsoleteTag = '17.0';
        }
        field(31113; "Unlimited Cash Desk Approval"; Boolean)
        {
            Caption = 'Unlimited Cash Desk Approval';
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
            ObsoleteTag = '17.0';
        }
    }

    keys
    {
        key(Key1; "User ID")
        {
            Clustered = true;
        }
        key(Key2; "Salespers./Purch. Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        NotificationSetup: Record "Notification Setup";
    begin
        // NAVCZ
        UserCheckLine.Reset();
        UserCheckLine.SetRange("User ID", "User ID");
        UserCheckLine.DeleteAll();
        // NAVCZ

        NotificationSetup.SetRange("User ID", "User ID");
        NotificationSetup.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        User: Record User;
    begin
        if "E-Mail" <> '' then
            exit;
        if "User ID" <> '' then
            exit;
        User.SetRange("User Name", "User ID");
        if User.FindFirst then
            "E-Mail" := CopyStr(User."Contact Email", 1, MaxStrLen("E-Mail"));
    end;

    var
        Text001: Label 'The %1 Salesperson/Purchaser code is already assigned to another User ID %2.';
        Text003: Label 'You cannot have both a %1 and %2. ';
        Text005: Label 'You cannot have approval limits less than zero.';
        UserCheckLine: Record "User Setup Line";
        SalesPersonPurchaser: Record "Salesperson/Purchaser";
        PrivacyBlockedGenericErr: Label 'Privacy Blocked must not be true for Salesperson / Purchaser %1.', Comment = '%1 = salesperson / purchaser code.';
        UserSetupManagement: Codeunit "User Setup Management";
        PhoneNoCannotContainLettersErr: Label 'must not contain letters';
        SelfCopyErr: Label 'You cannot copy a user setup into itself.';

    procedure CreateApprovalUserSetup(User: Record User)
    var
        UserSetup: Record "User Setup";
        ApprovalUserSetup: Record "User Setup";
    begin
        ApprovalUserSetup.Init();
        ApprovalUserSetup.Validate("User ID", User."User Name");
        ApprovalUserSetup.Validate("Sales Amount Approval Limit", GetDefaultSalesAmountApprovalLimit);
        ApprovalUserSetup.Validate("Purchase Amount Approval Limit", GetDefaultPurchaseAmountApprovalLimit);
        // NAVCZ
        ApprovalUserSetup.Validate("Bank Amount Approval Limit", GetDefaultBankApprovalLimit);
        ApprovalUserSetup.Validate("Cash Desk Amt. Approval Limit", GetDefaultCashDeskApprovalLimit);
        // NAVCZ
        ApprovalUserSetup.Validate("E-Mail", User."Contact Email");
        UserSetup.SetRange("Sales Amount Approval Limit", UserSetup.GetDefaultSalesAmountApprovalLimit);
        if UserSetup.FindFirst then
            ApprovalUserSetup.Validate("Approver ID", UserSetup."Approver ID");
        if ApprovalUserSetup.Insert() then;
    end;

    procedure GetDefaultSalesAmountApprovalLimit(): Integer
    var
        UserSetup: Record "User Setup";
        DefaultApprovalLimit: Integer;
        LimitedApprovers: Integer;
    begin
        UserSetup.SetRange("Unlimited Sales Approval", false);

        if UserSetup.FindFirst then begin
            DefaultApprovalLimit := UserSetup."Sales Amount Approval Limit";
            LimitedApprovers := UserSetup.Count();
            UserSetup.SetRange("Sales Amount Approval Limit", DefaultApprovalLimit);
            if LimitedApprovers = UserSetup.Count then
                exit(DefaultApprovalLimit);
        end;

        // Return 0 if no user setup exists or no default value is found
        exit(0);
    end;

    procedure GetDefaultPurchaseAmountApprovalLimit(): Integer
    var
        UserSetup: Record "User Setup";
        DefaultApprovalLimit: Integer;
        LimitedApprovers: Integer;
    begin
        UserSetup.SetRange("Unlimited Purchase Approval", false);

        if UserSetup.FindFirst then begin
            DefaultApprovalLimit := UserSetup."Purchase Amount Approval Limit";
            LimitedApprovers := UserSetup.Count();
            UserSetup.SetRange("Purchase Amount Approval Limit", DefaultApprovalLimit);
            if LimitedApprovers = UserSetup.Count then
                exit(DefaultApprovalLimit);
        end;

        // Return 0 if no user setup exists or no default value is found
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure GetDefaultBankApprovalLimit(): Integer
    var
        UserSetup: Record "User Setup";
        DefaultApprovalLimit: Integer;
        LimitedApprovers: Integer;
    begin
        // NAVCZ
        UserSetup.SetRange("Unlimited Bank Approval", false);

        if UserSetup.FindFirst then begin
            DefaultApprovalLimit := UserSetup."Bank Amount Approval Limit";
            LimitedApprovers := UserSetup.Count();
            UserSetup.SetRange("Bank Amount Approval Limit", DefaultApprovalLimit);
            if LimitedApprovers = UserSetup.Count then
                exit(DefaultApprovalLimit);
        end;

        // Return 0 if no user setup exists or no default value is found
        exit(0);
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure GetDefaultCashDeskApprovalLimit(): Integer
    var
        UserSetup: Record "User Setup";
        DefaultApprovalLimit: Integer;
        LimitedApprovers: Integer;
    begin
        // NAVCZ
        UserSetup.SetRange("Unlimited Cash Desk Approval", false);

        if UserSetup.FindFirst then begin
            DefaultApprovalLimit := UserSetup."Cash Desk Amt. Approval Limit";
            LimitedApprovers := UserSetup.Count();
            UserSetup.SetRange("Cash Desk Amt. Approval Limit", DefaultApprovalLimit);
            if LimitedApprovers = UserSetup.Count then
                exit(DefaultApprovalLimit);
        end;

        // Return 0 if no user setup exists or no default value is found
        exit(0);
    end;

    procedure HideExternalUsers()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        OriginalFilterGroup: Integer;
    begin
        if not EnvironmentInfo.IsSaaS then
            exit;

        OriginalFilterGroup := FilterGroup;
        FilterGroup := 2;
        CalcFields("License Type");
        SetFilter("License Type", '<>%1', "License Type"::"External User");
        FilterGroup := OriginalFilterGroup;
    end;

    local procedure UpdateSalesPerson(FieldNumber: Integer)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        xSalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        if "Salespers./Purch. Code" = '' then
            exit;
        if SalespersonPurchaser.Get("Salespers./Purch. Code") then begin
            xSalespersonPurchaser := SalespersonPurchaser;
            if FieldNumber in [fieldno("E-Mail"), FieldNo("Salespers./Purch. Code")] then begin
                SalespersonPurchaser."E-Mail" := CopyStr("E-Mail", 1, MaxStrLen(SalespersonPurchaser."E-Mail"));
                SalespersonPurchaser."Search E-Mail" := SalespersonPurchaser."E-Mail";
            end;
            if FieldNumber in [fieldno("Phone No."), FieldNo("Salespers./Purch. Code")] then
                SalespersonPurchaser."Phone No." := "Phone No.";

            if (SalespersonPurchaser."E-Mail" <> xSalespersonPurchaser."E-Mail") or
                (SalespersonPurchaser."Search E-Mail" <> xSalespersonPurchaser."Search E-Mail") or
                (SalespersonPurchaser."Phone No." <> xSalespersonPurchaser."Phone No.")
            then
                SalespersonPurchaser.Modify();
        end;
    end;

    local procedure ValidateSalesPersonPurchOnUserSetup(UserSetup2: Record "User Setup")
    begin
        if UserSetup2."Salespers./Purch. Code" <> '' then
            if SalesPersonPurchaser.Get(UserSetup2."Salespers./Purch. Code") then
                if SalesPersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalesPersonPurchaser) then
                    Error(PrivacyBlockedGenericErr, UserSetup2."Salespers./Purch. Code")
    end;

    procedure CheckAllowedPostingDates(NotificationType: Option Error,Notification)
    begin
        UserSetupManagement.CheckAllowedPostingDatesRange(
          "Allow Posting From", "Allow Posting To", NotificationType, DATABASE::"User Setup");
    end;

    procedure CopyTo(ToUserId: Code[50])
    var
        FromUserSetupLine: Record "User Setup Line";
        FromSelectedDimension: Record "Selected Dimension";
        OldUserSetup: Record "User Setup";
        UserSetup: Record "User Setup";
        UserSetupLine: Record "User Setup Line";
        SelectedDimension: Record "Selected Dimension";
    begin
        // NAVCZ
        if ToUserId = '' then
            exit;

        if "User ID" = ToUserId then
            Error(SelfCopyErr);

        if UserSetup.Get(ToUserId) then
            OldUserSetup := UserSetup;

        UserSetup.Init();
        UserSetup := Rec;
        UserSetup."User Name" := OldUserSetup."User Name";
        UserSetup."User ID" := ToUserId;
        if not UserSetup.Insert() then
            UserSetup.Modify();

        UserSetupLine.SetRange("User ID", ToUserId);
        UserSetupLine.DeleteAll();

        FromUserSetupLine.SetRange("User ID", "User ID");
        if FromUserSetupLine.FindSet then
            repeat
                UserSetupLine := FromUserSetupLine;
                UserSetupLine."User ID" := ToUserId;
                UserSetupLine.Insert();
            until FromUserSetupLine.Next = 0;

        SelectedDimension.SetRange("User ID", ToUserId);
        SelectedDimension.SetRange("Object Type", 1);
        SelectedDimension.SetRange("Object ID", DATABASE::"User Setup");
        SelectedDimension.DeleteAll();

        FromSelectedDimension.SetRange("User ID", "User ID");
        FromSelectedDimension.SetRange("Object Type", 1);
        FromSelectedDimension.SetRange("Object ID", DATABASE::"User Setup");
        if FromSelectedDimension.FindSet then
            repeat
                SelectedDimension := FromSelectedDimension;
                SelectedDimension."User ID" := ToUserId;
                SelectedDimension.Insert();
            until FromSelectedDimension.Next = 0;

        OnAfterCopyUserSetup(Rec, UserSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyUserSetup(FromUserSetup: Record "User Setup"; ToUserSetup: Record "User Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateApprovalAdministrator(var UserSetup: Record "User Setup"; var IsHandled: Boolean)
    begin
    end;
}

