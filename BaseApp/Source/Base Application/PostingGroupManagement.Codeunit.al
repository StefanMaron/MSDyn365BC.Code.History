codeunit 11768 "Posting Group Management"
{

    trigger OnRun()
    begin
    end;

    var
        CannotChangePostingGroupErr: Label 'You cannot change the value %1 to %2 because %3 has not been filled in.', Comment = '%1 = old posting group; %2 = new posting group; %3 = tablecaption of Subst. Vendor/Customer Posting Group';

    procedure CheckPostingGroupChange(NewPostingGroup: Code[20]; OldPostingGroup: Code[20]; Variant: Variant)
    var
        RecRef: RecordRef;
        CustomerVendorNo: Code[20];
        CheckedPostingGroup: Option "None",Customer,CustomerInService,Vendor;
    begin
        if OldPostingGroup = NewPostingGroup then
            exit;

        RecRef.GetTable(Variant);
        case RecRef.Number of
            DATABASE::"Sales Header":
                CheckPostingGroupChangeInSalesHeader(NewPostingGroup, OldPostingGroup);
            DATABASE::"Purchase Header":
                CheckPostingGroupChangeInPurchaseHeader(NewPostingGroup, OldPostingGroup);
            DATABASE::"Gen. Journal Line":
                CheckPostingGroupChangeInGenJnlLine(NewPostingGroup, OldPostingGroup, Variant);
            DATABASE::"Finance Charge Memo Header":
                CheckPostingGroupChangeInFinChrgMemoHeader(NewPostingGroup, OldPostingGroup);
            DATABASE::"Service Header":
                CheckPostingGroupChangeInServiceHeader(NewPostingGroup, OldPostingGroup);
            DATABASE::"Bank Acc. Reconciliation Line":
                CheckPostingGroupChangeInBankAccReconLine(NewPostingGroup, OldPostingGroup, Variant);
            DATABASE::"Cash Document Line":
                CheckPostingGroupChangeInCashDocLine(NewPostingGroup, OldPostingGroup, Variant);
            DATABASE::"Sales Advance Letter Header":
                CheckPostingGroupChangeInSalesAdvLetterHeader(NewPostingGroup, OldPostingGroup);
            DATABASE::"Purch. Advance Letter Header":
                CheckPostingGroupChangeInPurchAdvLetterHeader(NewPostingGroup, OldPostingGroup);
            DATABASE::"Credit Line":
                CheckPostingGroupChangeInCreditLine(NewPostingGroup, OldPostingGroup, Variant);
            else begin
                    OnCheckPostingGroupChange(NewPostingGroup, OldPostingGroup, RecRef, CheckedPostingGroup, CustomerVendorNo);
                    case CheckedPostingGroup of
                        CheckedPostingGroup::Customer:
                            CheckCustomerPostingGroupChangeAndCustomer(NewPostingGroup, OldPostingGroup, CustomerVendorNo);
                        CheckedPostingGroup::CustomerInService:
                            CheckCustomerPostingGroupChangeAndCustomerInService(NewPostingGroup, OldPostingGroup, CustomerVendorNo);
                        CheckedPostingGroup::Vendor:
                            CheckVendorPostingGroupChangeAndVendor(NewPostingGroup, OldPostingGroup, CustomerVendorNo);
                        else
                            exit;
                    end;
                end;
        end;
    end;

    local procedure CheckPostingGroupChangeInSalesHeader(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
        CheckCustomerPostingGroupChange(NewPostingGroup, OldPostingGroup);
    end;

    local procedure CheckPostingGroupChangeInPurchaseHeader(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
        CheckVendorPostingGroupChange(NewPostingGroup, OldPostingGroup);
    end;

    local procedure CheckPostingGroupChangeInGenJnlLine(NewPostingGroup: Code[20]; OldPostingGroup: Code[20]; GenJournalLine: Record "Gen. Journal Line")
    begin
        with GenJournalLine do
            case "Account Type" of
                "Account Type"::Customer:
                    CheckCustomerPostingGroupChangeAndCustomer(NewPostingGroup, OldPostingGroup, "Account No.");
                "Account Type"::Vendor:
                    CheckVendorPostingGroupChangeAndVendor(NewPostingGroup, OldPostingGroup, "Account No.");
                else
                    FieldError("Account Type");
            end;
    end;

    local procedure CheckPostingGroupChangeInFinChrgMemoHeader(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
        CheckCustomerPostingGroupChange(NewPostingGroup, OldPostingGroup);
    end;

    local procedure CheckPostingGroupChangeInServiceHeader(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
        CheckCustomerPostingGroupChangeAndCustomerInService(NewPostingGroup, OldPostingGroup, '');
    end;

    local procedure CheckPostingGroupChangeInBankAccReconLine(NewPostingGroup: Code[20]; OldPostingGroup: Code[20]; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        with BankAccReconciliationLine do
            case "Account Type" of
                "Account Type"::Customer:
                    CheckCustomerPostingGroupChangeAndCustomer(NewPostingGroup, OldPostingGroup, "Account No.");
                "Account Type"::Vendor:
                    CheckVendorPostingGroupChangeAndVendor(NewPostingGroup, OldPostingGroup, "Account No.");
                else
                    FieldError("Account Type");
            end;
    end;

    local procedure CheckPostingGroupChangeInCashDocLine(NewPostingGroup: Code[20]; OldPostingGroup: Code[20]; CashDocumentLine: Record "Cash Document Line")
    begin
        with CashDocumentLine do
            case "Account Type" of
                "Account Type"::Customer:
                    CheckCustomerPostingGroupChange(NewPostingGroup, OldPostingGroup);
                "Account Type"::Vendor:
                    CheckVendorPostingGroupChange(NewPostingGroup, OldPostingGroup);
            end;
    end;

    local procedure CheckPostingGroupChangeInSalesAdvLetterHeader(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
        CheckCustomerPostingGroupChange(NewPostingGroup, OldPostingGroup);
    end;

    local procedure CheckPostingGroupChangeInPurchAdvLetterHeader(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
        CheckVendorPostingGroupChange(NewPostingGroup, OldPostingGroup);
    end;

    local procedure CheckPostingGroupChangeInCreditLine(NewPostingGroup: Code[20]; OldPostingGroup: Code[20]; CreditLine: Record "Credit Line")
    begin
        with CreditLine do
            case "Source Type" of
                "Source Type"::Customer:
                    CheckCustomerPostingGroupChange(NewPostingGroup, OldPostingGroup);
                "Source Type"::Vendor:
                    CheckVendorPostingGroupChange(NewPostingGroup, OldPostingGroup);
                else
                    FieldError("Source Type");
            end;
    end;

    procedure CheckCustomerPostingGroupChange(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
        CheckCustomerPostingGroupChangeAndCustomer(NewPostingGroup, OldPostingGroup, '');
    end;

    procedure CheckVendorPostingGroupChange(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    begin
        CheckVendorPostingGroupChangeAndVendor(NewPostingGroup, OldPostingGroup, '');
    end;

    procedure CheckCustomerPostingGroupChangeAndCustomer(NewPostingGroup: Code[20]; OldPostingGroup: Code[20]; CustomerNo: Code[20])
    begin
        CheckAllowChangeSalesSetup;
        if not HasCustomerSamePostingGroup(NewPostingGroup, CustomerNo) then
            CheckCustomerPostingGroupSubstSetup(NewPostingGroup, OldPostingGroup);
    end;

    procedure CheckCustomerPostingGroupChangeAndCustomerInService(NewPostingGroup: Code[20]; OldPostingGroup: Code[20]; CustomerNo: Code[20])
    begin
        CheckAllowChangeServiceSetup;
        if not HasCustomerSamePostingGroup(NewPostingGroup, CustomerNo) then
            CheckCustomerPostingGroupSubstSetup(NewPostingGroup, OldPostingGroup);
    end;

    procedure CheckVendorPostingGroupChangeAndVendor(NewPostingGroup: Code[20]; OldPostingGroup: Code[20]; VendorNo: Code[20])
    begin
        CheckAllowChangePurchaseSetup;
        if not HasVendorSamePostingGroup(NewPostingGroup, VendorNo) then
            CheckVendorPostingGroupSubstSetup(NewPostingGroup, OldPostingGroup);
    end;

    procedure CheckCustomerPostingGroupSubstSetup(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    var
        SubstCustomerPostingGroup: Record "Subst. Customer Posting Group";
    begin
        if not SubstCustomerPostingGroup.Get(OldPostingGroup, NewPostingGroup) then
            Error(CannotChangePostingGroupErr, OldPostingGroup, NewPostingGroup, SubstCustomerPostingGroup.TableCaption);
    end;

    procedure CheckVendorPostingGroupSubstSetup(NewPostingGroup: Code[20]; OldPostingGroup: Code[20])
    var
        SubstVendorPostingGroup: Record "Subst. Vendor Posting Group";
    begin
        if not SubstVendorPostingGroup.Get(OldPostingGroup, NewPostingGroup) then
            Error(CannotChangePostingGroupErr, OldPostingGroup, NewPostingGroup, SubstVendorPostingGroup.TableCaption);
    end;

    procedure CheckAllowChangeSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup.TestField("Allow Alter Posting Groups");
    end;

    procedure CheckAllowChangeServiceSetup()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get;
        ServiceMgtSetup.TestField("Allow Alter Cust. Post. Groups");
    end;

    procedure CheckAllowChangePurchaseSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.TestField("Allow Alter Posting Groups");
    end;

    procedure HasCustomerSamePostingGroup(NewPostingGroup: Code[20]; CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then
            exit(NewPostingGroup = Customer."Customer Posting Group");
        exit(false);
    end;

    procedure HasVendorSamePostingGroup(NewPostingGroup: Code[20]; VendorNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then
            exit(NewPostingGroup = Vendor."Vendor Posting Group");
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPostingGroupChange(NewPostingGroup: Code[20]; OldPostingGroup: Code[20]; RecRef: RecordRef; var CheckedPostingGroup: Option "None",Customer,CustomerInService,Vendor; var CustomerVendorNo: Code[20])
    begin
    end;
}

