codeunit 1636 "Office Contact Handler"
{
    TableNo = "Office Add-in Context";

    trigger OnRun()
    begin
        if (Email <> '') or ("Contact No." <> '') then
            FindAndRedirectContact(Rec)
        else
            ShowContactSelection(Rec);
    end;

    var
        SelectAContactTxt: Label 'Select a contact';

    local procedure FindAndRedirectContact(TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        TempCompany: Record Company temporary;
        TempOfficeContactDetails: Record "Office Contact Details" temporary;
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        OfficeMgt: Codeunit "Office Management";
    begin
        AssistedCompanySetup.GetAllowedCompaniesForCurrnetUser(TempCompany);
        if TempOfficeAddinContext.Company <> '' then
            TempCompany.SetRange(Name, CopyStr(TempOfficeAddinContext.Company, 1, 30));
        if TempOfficeAddinContext."Contact No." <> '' then
            Contact.SetRange("No.", TempOfficeAddinContext."Contact No.");

        if TempCompany.FindSet() then
            repeat
                Contact.ChangeCompany(TempCompany.Name);
                ContactBusinessRelation.ChangeCompany(TempCompany.Name);
                FindContacts(TempOfficeAddinContext, TempOfficeContactDetails, Contact, ContactBusinessRelation, TempCompany.Name);
                ContactBusinessRelation.Reset();
            until TempCompany.Next = 0;


        if TempOfficeContactDetails.IsEmpty() then begin
            Page.Run(Page::"Office New Contact Dlg");
            exit;
        end;

        with TempOfficeContactDetails do begin
            if (Count() > 1) and (TempOfficeAddinContext.Command <> '') then
                SetRange("Associated Table", TempOfficeAddinContext.CommandType);

            if Count() = 1 then begin
                OfficeMgt.ChangeCompany(Company);
                FindFirst;
                ShowCustomerVendor(TempOfficeAddinContext, Contact, "Associated Table", GetContactNo);
                exit;
            end;

            SetRange(Type, Type::"Contact Person");
            if Count() = 1 then begin
                OfficeMgt.ChangeCompany(Company);
                FindFirst;
                ShowCustomerVendor(TempOfficeAddinContext, Contact, "Associated Table", GetContactNo);
                exit;
            end;

            SetRange(Type);
            SetRange("Associated Table");
            if Count() > 1 then begin
                Page.Run(Page::"Office Contact Associations", TempOfficeContactDetails);
            end;
        end;
    end;

    local procedure FindContacts(TempOfficeAddinContext: Record "Office Add-in Context" temporary; var TempOfficeContactDetails: Record "Office Contact Details" temporary; var Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; Company: Text[50])
    begin
        if TempOfficeAddinContext."Contact No." <> '' then
            Contact.SetRange("No.", TempOfficeAddinContext."Contact No.")
        else
            Contact.SetRange("Search E-Mail", UPPERCASE(TempOfficeAddinContext.Email));

        if not Contact.IsEmpty() then
            CollectMultipleContacts(Contact, ContactBusinessRelation, TempOfficeContactDetails, TempOfficeAddinContext, Company);
    end;

    procedure ShowContactSelection(OfficeAddinContext: Record "Office Add-in Context")
    var
        Contact: Record Contact;
        ContactList: Page "Contact List";
    begin
        FilterContacts(OfficeAddinContext, Contact);
        ContactList.SetTableView(Contact);
        ContactList.LookupMode(true);
        ContactList.Caption(SelectAContactTxt);
        if ContactList.LookupMode() then;
        ContactList.Run();
    end;

    procedure ShowCustomerVendor(TempOfficeAddinContext: Record "Office Add-in Context" temporary; Contact: Record Contact; AssociatedTable: Option; LinkNo: Code[20])
    var
        Customer: Record Customer;
        OfficeContactDetails: Record "Office Contact Details";
        Vendor: Record Vendor;
    begin
        case AssociatedTable of
            OfficeContactDetails."Associated Table"::Customer:
                begin
                    if TempOfficeAddinContext.CommandType = OfficeContactDetails."Associated Table"::Vendor then
                        Page.Run(Page::"Office No Vendor Dlg", Contact)
                    else
                        if Customer.Get(LinkNo) then
                            RedirectCustomer(Customer, TempOfficeAddinContext);
                    exit;
                end;
            OfficeContactDetails."Associated Table"::Vendor:
                begin
                    if TempOfficeAddinContext.CommandType = OfficeContactDetails."Associated Table"::Customer then
                        Page.Run(Page::"Office No Customer Dlg", Contact)
                    else
                        if Vendor.Get(LinkNo) then
                            RedirectVendor(Vendor, TempOfficeAddinContext);
                    exit;
                end;
            else
                if TempOfficeAddinContext.CommandType = OfficeContactDetails."Associated Table"::Customer then begin
                    Page.Run(Page::"Office No Customer Dlg", Contact);
                    exit;
                end;
                if TempOfficeAddinContext.CommandType = OfficeContactDetails."Associated Table"::Vendor then begin
                    Page.Run(Page::"Office No Vendor Dlg", Contact);
                    exit;
                end;
        end;

        Contact.Get(LinkNo);
        Page.Run(Page::"Contact Card", Contact)
    end;

    local procedure CollectMultipleContacts(var Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; var TempOfficeContactDetails: Record "Office Contact Details" temporary; TempOfficeAddinContext: Record "Office Add-in Context" temporary; ContactCompany: Text[50])
    begin
        FilterContactBusinessRelations(Contact, ContactBusinessRelation);
        if TempOfficeAddinContext.IsAppointment then
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        if ContactBusinessRelation.FindSet() then
            repeat
                ContactBusinessRelation.CalcFields("Business Relation Description");
                with TempOfficeContactDetails do
                    if not Get(ContactBusinessRelation."Contact No.", Contact.Type, ContactBusinessRelation."Link to Table", ContactCompany) then begin
                        Clear(TempOfficeContactDetails);
                        Init();
                        TransferFields(ContactBusinessRelation);
                        "Contact Name" := Contact.Name;
                        Company := ContactCompany;
                        Type := Contact.Type;
                        "Business Relation Description" := ContactBusinessRelation."Business Relation Description";
                        if ContactBusinessRelation."Link to Table" = TempOfficeAddinContext.CommandType then begin
                            "Contact No." := Contact."No.";
                            "Associated Table" := TempOfficeAddinContext.CommandType;
                        end;
                        Insert();
                    end;
            until ContactBusinessRelation.Next() = 0
        else
            if Contact.FindSet() then
                repeat
                    CreateUnlinkedContactAssociation(TempOfficeContactDetails, Contact, ContactCompany);
                until Contact.Next() = 0;
    end;

    local procedure CreateUnlinkedContactAssociation(var TempOfficeContactDetails: Record "Office Contact Details" temporary; Contact: Record Contact; ContactCompany: Text)
    begin
        Clear(TempOfficeContactDetails);
        with TempOfficeContactDetails do begin
            SetRange("No.", Contact."Company No.");
            if FindFirst() and (Type = Contact.Type::Company) then
                Delete();

            if IsEmpty() then begin
                Init();
                "No." := Contact."Company No.";
                if "No." = '' then
                    "No." := Contact."No.";
                "Contact No." := Contact."No.";
                "Contact Name" := Contact.Name;
                Company := CopyStr(ContactCompany, 1, 50);
                Type := Contact.Type;
                Insert();
            end;

            SetRange("No.");
        end;
    end;

    local procedure FilterContactBusinessRelations(var Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation")
    var
        ContactFilter: Text;
    begin
        // Filter contact business relations based on the specified list of contacts
        if Contact.FindSet() then
            repeat
                if StrPos(ContactFilter, Contact."No.") = 0 then
                    ContactFilter += Contact."No." + '|';
                if (StrPos(ContactFilter, Contact."Company No.") = 0) and (Contact."Company No." <> '') then
                    ContactFilter += Contact."Company No." + '|';
            until Contact.Next = 0;

        ContactBusinessRelation.SetFilter("Contact No.", DelChr(ContactFilter, '>', '|'));
    end;

    local procedure FilterContacts(OfficeAddinContext: Record "Office Add-in Context"; var Contact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        with ContactBusinessRelation do
            case true of
                OfficeAddinContext.Command <> '':
                    SetRange("Link to Table", OfficeAddinContext.CommandType);
                OfficeAddinContext.IsAppointment:
                    SetRange("Link to Table", "Link to Table"::Customer);
                else
                    exit;
            end;

        if ContactBusinessRelation.FindSet then begin
            Contact.FilterGroup(-1);
            repeat
                Contact.SetRange("Company No.", ContactBusinessRelation."Contact No.");
                Contact.SetRange("No.", ContactBusinessRelation."Contact No.");
                if Contact.FindSet() then
                    repeat
                        Contact.Mark(true);
                    until Contact.Next() = 0;
            until ContactBusinessRelation.Next() = 0;

            Contact.MarkedOnly(true);
        end;
    end;

    local procedure RedirectCustomer(Customer: Record Customer; var TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    var
        OfficeDocumentHandler: Codeunit "Office Document Handler";
    begin
        Page.Run(Page::"Customer Card", Customer);
        OfficeDocumentHandler.HandleSalesCommand(Customer, TempOfficeAddinContext);
    end;

    local procedure RedirectVendor(Vendor: Record Vendor; var TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    var
        OfficeDocumentHandler: Codeunit "Office Document Handler";
    begin
        Page.Run(Page::"Vendor Card", Vendor);
        OfficeDocumentHandler.HandlePurchaseCommand(Vendor, TempOfficeAddinContext);
    end;

    [EventSubscriber(ObjectType::Page, 5052, 'OnClosePageEvent', '', false, false)]
    local procedure OnContactSelected(var Rec: Record Contact)
    var
        TempOfficeAddinContext: Record "Office Add-in Context" temporary;
        OfficeMgt: Codeunit "Office Management";
    begin
        if OfficeMgt.IsAvailable() then begin
            OfficeMgt.GetContext(TempOfficeAddinContext);
            if TempOfficeAddinContext.Email = '' then begin
                TempOfficeAddinContext.Name := Rec.Name;
                TempOfficeAddinContext.Email := Rec."E-Mail";
                TempOfficeAddinContext."Contact No." := Rec."No.";
                TempOfficeAddinContext.Company := CompanyName();
                OfficeMgt.AddRecipient(Rec.Name, Rec."E-Mail");
                OfficeMgt.InitializeContext(TempOfficeAddinContext);
            end;
        end;
    end;
}

