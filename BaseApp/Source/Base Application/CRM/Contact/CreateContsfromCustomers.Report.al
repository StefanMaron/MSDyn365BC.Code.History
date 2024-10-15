namespace Microsoft.CRM.Contact;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Setup;
using Microsoft.Sales.Customer;

report 5195 "Create Conts. from Customers"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Create Contacts from Customers';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Currency Code";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1);

                with ContBusRel do begin
                    SetRange("Link to Table", "Link to Table"::Customer);
                    SetRange("No.", Customer."No.");
                    if FindFirst() then
                        CurrReport.Skip();
                end;

                Cont.Init();
                Cont.TransferFields(Customer);
                Cont."No." := '';
                OnBeforeSetSkipDefaults(Customer, Cont);
                Cont.SetSkipDefault();
                OnBeforeContactInsert(Customer, Cont);
                Cont.Insert(true);
                DuplMgt.MakeContIndex(Cont);

                if not DuplicateContactExist then
                    DuplicateContactExist := DuplMgt.DuplicateExist(Cont);

                with ContBusRel do begin
                    Init();
                    "Contact No." := Cont."No.";
                    "Business Relation Code" := RMSetup."Bus. Rel. Code for Customers";
                    "Link to Table" := "Link to Table"::Customer;
                    "No." := Customer."No.";
                    Insert();
                end;

                InsertNewContactIfNeeded(Customer);
                Modify(true);
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();

                if DuplicateContactExist then
                    DuplMgt.Notify();
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text000 + Text001, "No.");
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        cnt: Integer;
    begin
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Customers");
        cnt := Customer.Count();
        if GuiAllowed then
            if cnt > 100 then
                if not Confirm(StrSubstNo(TooManyRecordsQst, cnt)) then
                    CurrReport.Quit();
    end;

    var
        RMSetup: Record "Marketing Setup";
        Cont: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        DuplMgt: Codeunit DuplicateManagement;
        Window: Dialog;
        DuplicateContactExist: Boolean;

        Text000: Label 'Processing customers...\\';
        Text001: Label 'Customer No.    #1##########';
        TooManyRecordsQst: Label 'This process will take several minutes because it involves %1 customers. It is recommended that you schedule the process to run as a background task.\\Do you want to start the process immediately anyway?', Comment = '%1 = number of records';

    local procedure InsertNewContactIfNeeded(var Customer: Record Customer)
    var
        CustContUpdate: Codeunit "CustCont-Update";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertNewContactIfNeeded(ContBusRel, Customer, IsHandled);
        if IsHandled then
            exit;

        if Customer.Contact = '' then
            Customer."Primary Contact No." := Cont."No."
        else
            CustContUpdate.InsertNewContactPerson(Customer, false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContactInsert(Customer: Record Customer; var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewContactIfNeeded(ContactBusinessRelation: Record "Contact Business Relation"; var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSkipDefaults(var Customer: Record Customer; var Contact: Record Contact)
    begin
    end;
}

