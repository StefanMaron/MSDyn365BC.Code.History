report 5193 "Create Conts. from Bank Accs."
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Create Contacts from Bank Accounts';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            RequestFilterFields = "No.", "Search Name", "Bank Acc. Posting Group", "Currency Code";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1);

                with ContBusRel do begin
                    SetRange("Link to Table", "Link to Table"::"Bank Account");
                    SetRange("No.", "Bank Account"."No.");
                    if FindFirst then
                        CurrReport.Skip();
                end;

                Cont.Init();
                Cont.TransferFields("Bank Account");
                Cont."No." := '';
                OnBeforeSetSkipDefaults("Bank Account", Cont);
                Cont.SetSkipDefault;
                Cont.Insert(true);
                DuplMgt.MakeContIndex(Cont);

                if not DuplicateContactExist then
                    DuplicateContactExist := DuplMgt.DuplicateExist(Cont);

                with ContBusRel do begin
                    Init;
                    "Contact No." := Cont."No.";
                    "Business Relation Code" := RMSetup."Bus. Rel. Code for Bank Accs.";
                    "Link to Table" := "Link to Table"::"Bank Account";
                    "No." := "Bank Account"."No.";
                    Insert;
                end;
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
    begin
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Bank Accs.");
    end;

    var
        Text000: Label 'Processing vendors...\\';
        Text001: Label 'Bank Account No.  #1##########';
        RMSetup: Record "Marketing Setup";
        Cont: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        DuplMgt: Codeunit DuplicateManagement;
        Window: Dialog;
        DuplicateContactExist: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSkipDefaults(var BankAccount: Record "Bank Account"; var Contact: Record Contact)
    begin
    end;
}

