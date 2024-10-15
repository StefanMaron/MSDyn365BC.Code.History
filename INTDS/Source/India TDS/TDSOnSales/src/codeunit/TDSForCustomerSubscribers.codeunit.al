codeunit 18661 "TDS For Customer Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostCustomerEntry', '', false, false)]
    local procedure PostCustEntry(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line")
    begin
        GenJnlLine."TDS Certificate Receivable" := SalesHeader."TDS Certificate Receivable";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnAfterCopyCustLedgerEntryFromGenJnlLine', '', false, false)]
    local procedure InsertTDSSectionCodeinVendLedgerEntry(GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")

    begin
        CustLedgerEntry."TDS Certificate Receivable" := GenJournalLine."TDS Certificate Receivable";
        CustLedgerEntry."TDS Section Code" := GenJournalLine."TDS Section Code";
    end;

    procedure TDSSectionCodeLookupGenLineForCustomer(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; SetTDSSection: boolean)
    var
        Section: Record "TDS Section";
        CustomerAllowedSections: Record "Customer Allowed Sections";
    begin
        if (GenJournalLine."Account Type" = GenJournalLine."Account Type"::Customer) and GenJournalLine."TDS Certificate Receivable" then begin
            CustomerAllowedSections.Reset();
            CustomerAllowedSections.SetRange("Customer No", GenJournalLine."Account No.");
            if CustomerAllowedSections.FindSet() then
                repeat
                    section.setrange(code, CustomerAllowedSections."TDS Section");
                    if Section.FindFirst() then
                        Section.Mark(true);
                until CustomerAllowedSections.Next() = 0;
            Section.setrange(code);
            section.MarkedOnly(true);
            if page.RunModal(Page::"TDS Sections", Section) = Action::LookupOK then
                checkDefaultandAssignTDSSection(GenJournalLine, Section.Code, SetTDSSection);
        end;
    end;

    local procedure CheckDefaultAndAssignTDSSection(var GenJournalLine: Record "Gen. Journal Line"; TDSSectionCode: Code[10]; SetTDSSection: boolean)
    var
        CustomerAllowedSections: Record "Customer Allowed Sections";
    begin
        if (GenJournalLine."Account Type" = GenJournalLine."Account Type"::Customer) and GenJournalLine."TDS Certificate Receivable" then begin
            CustomerAllowedSections.Reset();
            CustomerAllowedSections.SetRange("Customer No", GenJournalLine."Account No.");
            CustomerAllowedSections.SetRange("TDS Section", TDSSectionCode);
            if CustomerAllowedSections.findfirst() then begin
                if SetTDSSection then
                    GenJournalLine.Validate("TDS Section Code", CustomerAllowedSections."TDS Section")
            end else
                ConfirmAssignTDSSection(GenJournalLine, TDSSectionCode, SetTDSSection);
        end;
    end;

    local procedure ConfirmAssignTDSSection(var GenJournalLine: Record "Gen. Journal Line"; TDSSectionCode: code[10]; SetTDSSection: boolean)
    var
        CustomerAllowedSections: Record "Customer Allowed Sections";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if (GenJournalLine."Account Type" = GenJournalLine."Account Type"::Customer) and GenJournalLine."TDS Certificate Receivable" then begin
            if ConfirmManagement.GetResponseOrDefault(strSubstNo(ConfirmMessageMsg, TDSSectionCode, GenJournalLine."Account No."), true) then
                CustomerAllowedSections.init();
            CustomerAllowedSections."TDS Section" := TDSSectionCode;
            CustomerAllowedSections."Customer No" := GenJournalLine."Account No.";
            CustomerAllowedSections.insert();
            if SetTDSSection then
                GenJournalLine.Validate("TDS Section Code", CustomerAllowedSections."TDS Section")
        end;
    end;

    var
        ConfirmMessageMsg: label 'TDS Section Code %1 is not attached with Customer No. %2, Do you want to assign to Customer & Continue ?', Comment = '%1 = TDS Section Code,%2 = Customer No.';
}