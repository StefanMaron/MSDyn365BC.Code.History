report 5194 "Create Conts. from Vendors"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Create Contacts from Vendors';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            RequestFilterFields = "No.", "Search Name", "Vendor Posting Group", "Currency Code";

            trigger OnAfterGetRecord()
            var
                VendContUpdate: Codeunit "VendCont-Update";
            begin
                Window.Update(1);

                with ContBusRel do begin
                    SetRange("Link to Table", "Link to Table"::Vendor);
                    SetRange("No.", Vendor."No.");
                    if FindFirst then
                        CurrReport.Skip();
                end;

                Cont.Init();
                Cont.TransferFields(Vendor);
                Cont."No." := '';
                OnBeforeSetSkipDefaults(Vendor, Cont);
                Cont.SetSkipDefault;
                OnBeforeContactInsert(Vendor, Cont);
                Cont.Insert(true);
                DuplMgt.MakeContIndex(Cont);

                if not DuplicateContactExist then
                    DuplicateContactExist := DuplMgt.DuplicateExist(Cont);

                with ContBusRel do begin
                    Init;
                    "Contact No." := Cont."No.";
                    "Business Relation Code" := RMSetup."Bus. Rel. Code for Vendors";
                    "Link to Table" := "Link to Table"::Vendor;
                    "No." := Vendor."No.";
                    Insert;
                end;

                if Contact = '' then
                    "Primary Contact No." := Cont."No."
                else
                    VendContUpdate.InsertNewContactPerson(Vendor, false);
                Modify(true);
            end;

            trigger OnPostDataItem()
            begin
                Window.Close;

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
        RMSetup.TestField("Bus. Rel. Code for Vendors");
        cnt := Vendor.Count();
        if GuiAllowed then
            if cnt > 100 then
                if not Confirm(StrSubstNo(TooManyRecordsQst, cnt)) then
                    CurrReport.Quit();
    end;

    var
        Text000: Label 'Processing vendors...\\';
        Text001: Label 'Vendor No.      #1##########';
        TooManyRecordsQst: Label 'This process will take several minutes because it involves %1 vendors. It is recommended that you schedule the process to run as a background task.\\Do you want to start the process immediately anyway?', Comment = '%1 = number of records';
        RMSetup: Record "Marketing Setup";
        Cont: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        DuplMgt: Codeunit DuplicateManagement;
        Window: Dialog;
        DuplicateContactExist: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContactInsert(Vendor: Record Vendor; var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSkipDefaults(var Vendor: Record Vendor; var Contact: Record Contact)
    begin
    end;
}

