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
                        CurrReport.Skip;
                end;

                Cont.Init;
                Cont.TransferFields(Vendor);
                Cont."No." := '';
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

                if DuplicateContactExist then begin
                    Commit;
                    PAGE.RunModal(PAGE::"Contact Duplicates");
                end;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text000 +
                  Text001, "No.");
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
    begin
        RMSetup.Get;
        RMSetup.TestField("Bus. Rel. Code for Vendors");
    end;

    var
        Text000: Label 'Processing vendors...\\';
        Text001: Label 'Vendor No.      #1##########';
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
}

