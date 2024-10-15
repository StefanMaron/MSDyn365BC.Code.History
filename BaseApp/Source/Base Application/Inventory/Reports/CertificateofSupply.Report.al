namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Service.History;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;

report 780 "Certificate of Supply"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/CertificateofSupply.rdlc';
    Caption = 'Certificate of Supply';

    dataset
    {
        dataitem(CertificateOfSupply; "Certificate of Supply")
        {
            RequestFilterFields = "Document Type", "Document No.";
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(COMPANYADDRESS; CompanyInfo.Address)
                {
                }
                column(COMPANYADDRESS2; CompanyInfo."Address 2")
                {
                }
                column(COMPANYCITY; CompanyInfo.City)
                {
                }
                column(COMPANYCOUNTRYCODE; CompanyInfo."Country/Region Code")
                {
                }
                column(Quantity_of_the_object_of_the_supply_Caption; Quantity_of_the_object_of_the_supply_Lbl)
                {
                }
                column(Standard_commercial_description___in_the_case_of_vehicles__including_vehicle_identification_number_Caption; Standard_commercial_description___in_the_case_of_vehicles__including_vehicle_identification_number_Lbl)
                {
                }
                column(Date_the_object_of_the_supply_was_received_in_the_Member_State; Date_the_object_of_the_supply_was_received_in_the_Member_State_of_entry_Lbl)
                {
                }
                column(Date_the_transportation_ended_if_the_customer_transported_the_object_of_the_supply_himself_or_herself_Caption; Date_the_transportation_ended_if_the_customer_transported_the_object_of_the_supply_himself_or_herself_Lbl)
                {
                }
                column(in_atCaption; in_atLbl)
                {
                }
                column(Member_State_and_place_of_entry_as_part_of_the_transport_or_dispatch_of_the_object_Caption; Member_State_and_place_of_entry_as_part_of_the_transport_or_dispatch_of_the_object_Lbl)
                {
                }
                column(Date_of_issue_of_the_certificate_Caption; Date_of_issue_of_the_certificate_Lbl)
                {
                }
                column(Signature_of_the_customer_or_of_the_authorised_representative_as_well_as_the_signatory_s_name_in_capitals_Caption; Signature_of_the_customer_or_of_the_authorised_representative_as_well_as_the_signatory_s_name_in_capitals_Lbl)
                {
                }
                column(Reference_Document_Caption; Reference_Document_Lbl)
                {
                }
                column(Shipment_Method_Caption; Shipment_Method_Lbl)
                {
                }
                column(Vehicle_Registration_No_Caption; Vehicle_Registration_No_Lbl)
                {
                }
                column(Certification_of_the_entry_of_the_object_of_an_intra___Community_supply_into_another_Caption; Certification_of_the_entry_of_the_object_of_an_intra___Community_supply_into_another_Lbl)
                {
                }
                column(EU_Member_State__Entry_Certificate_Caption; EU_Member_State__Entry_Certificate_Lbl)
                {
                }
                column(Name_and_address_of_the_customer_of_the_intra_Community_supply__if_applicable__E_Mail_address_Caption; Name_and_address_of_the_customer_of_the_intra_Community_supply__if_applicable__E_Mail_address_Lbl)
                {
                }
                column(I_as_the_customer_hereby_certify_my_receipt_the_entry_of_the_following_object_of_an_intra___Community_supplyCaption; I_as_the_customer_hereby_certify_my_receipt_the_entry_of_the_following_object_of_an_intra___Community_supplyLbl)
                {
                }
                column(on_Caption; onLbl)
                {
                }
                column(Received_Caption; receivedLbl)
                {
                }
                column(delete_As_Appropriate_Caption; deleteAsAppropriateLbl)
                {
                }
                column(No; TempServiceShipmentHeader."No.")
                {
                }
                column(Bill_to_Name; TempServiceShipmentHeader."Bill-to Name")
                {
                }
                column(Bill_to_Address; TempServiceShipmentHeader."Bill-to Address")
                {
                }
                column(Bill_to_Address2; TempServiceShipmentHeader."Bill-to Address 2")
                {
                }
                column(Bill_to_City; TempServiceShipmentHeader."Bill-to City")
                {
                }
                column(Bill_To_CountryRegion_Code; TempServiceShipmentHeader."Bill-to Country/Region Code")
                {
                }
                column(EMail; TempServiceShipmentHeader."E-Mail")
                {
                }
                column(Ship_to_Address; TempServiceShipmentHeader."Ship-to Address")
                {
                }
                column(Ship_to_Address2; TempServiceShipmentHeader."Ship-to Address 2")
                {
                }
                column(Ship_to_City; TempServiceShipmentHeader."Ship-to City")
                {
                }
                column(Ship_to_Country_Region_Code; TempServiceShipmentHeader."Ship-to Country/Region Code")
                {
                }
                column(Ship_to_Name; TempServiceShipmentHeader."Ship-to Name")
                {
                }
                column(Shipment_Method_Code; CertificateOfSupply."Shipment Method Code")
                {
                }
                column(Vehicle_Registration_No; CertificateOfSupply."Vehicle Registration No.")
                {
                }
                column(PrintLineDetails; PrintLineDetails)
                {
                }
                dataitem("<Integer2>"; "Integer")
                {
                    DataItemTableView = sorting(Number) order(ascending) where(Number = filter(1 ..));
                    column(Item_No_Caption; TempServiceShipmentLine.FieldCaption("No."))
                    {
                    }
                    column(Decription_Caption; TempServiceShipmentLine.FieldCaption(Description))
                    {
                    }
                    column(Quantity_Caption; TempServiceShipmentLine.FieldCaption(Quantity))
                    {
                    }
                    column(Unit_of_Measure_Caption; TempServiceShipmentLine.FieldCaption("Unit of Measure"))
                    {
                    }
                    column(Line_No; TempServiceShipmentLine."Line No.")
                    {
                    }
                    column(Item_No; TempServiceShipmentLine."No.")
                    {
                    }
                    column(Description; TempServiceShipmentLine.Description)
                    {
                    }
                    column(Quantity; TempServiceShipmentLine.Quantity)
                    {
                    }
                    column(Unit_of_Measure; TempServiceShipmentLine."Unit of Measure Code")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not TempServiceShipmentLine.FindSet() then
                                CurrReport.Break()
                        end else
                            if TempServiceShipmentLine.Next() = 0 then
                                CurrReport.Break();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TempServiceShipmentLine.SetFilter(Quantity, '<>%1', 0);
                    end;
                }

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode() then
                        CertificateOfSupply.SetPrintedTrue();
                end;
            }

            trigger OnAfterGetRecord()
            var
                Language: Codeunit Language;
            begin
                Clear(TempServiceShipmentHeader);
                TempServiceShipmentLine.Reset();
                TempServiceShipmentLine.DeleteAll();
                CurrReport.Language := Language.GetLanguageIdOrDefault(GetLanguageCode(CertificateOfSupply));
                CurrReport.FormatRegion := Language.GetFormatRegionOrDefault(GetFormatRegionCode(CertificateOfSupply));
                SetSource(CertificateOfSupply);
                if PrintLineDetails then
                    GetLines(CertificateOfSupply);
            end;

            trigger OnPreDataItem()
            var
                SalesShipmentHeader: Record "Sales Shipment Header";
                ServiceShipmentHeader: Record "Service Shipment Header";
                ReturnShipmentHeader: Record "Return Shipment Header";
                CertificateOfSupply2: Record "Certificate of Supply";
            begin
                if (GetFilter("Document Type") = '') xor
                   (GetRangeMin("Document Type") <> GetRangeMax("Document Type"))
                then
                    Error(MultipleDocumentsErr);

                if CreateCertificatesofSupply then
                    case GetRangeMin("Document Type") of
                        "Document Type"::"Sales Shipment":
                            begin
                                CopyFilter("Document No.", SalesShipmentHeader."No.");
                                OnCertificateOfSupplyOnPreDataItemOnAfterFilterForSalesShipmentHeader(CertificateOfSupply, SalesShipmentHeader);
                                if SalesShipmentHeader.FindSet() then
                                    repeat
                                        CertificateOfSupply2.InitFromSales(SalesShipmentHeader);
                                        CertificateOfSupply2.SetRequired(SalesShipmentHeader."No.");
                                    until SalesShipmentHeader.Next() = 0;
                            end;
                        "Document Type"::"Service Shipment":
                            begin
                                CopyFilter("Document No.", ServiceShipmentHeader."No.");
                                OnCertificateOfSupplyOnPreDataItemOnAfterFilterForServiceShipmentHeader(CertificateOfSupply, ServiceShipmentHeader);
                                if ServiceShipmentHeader.FindSet() then
                                    repeat
                                        CertificateOfSupply2.InitFromService(ServiceShipmentHeader);
                                        CertificateOfSupply2.SetRequired(ServiceShipmentHeader."No.")
                                    until ServiceShipmentHeader.Next() = 0;
                            end;
                        "Document Type"::"Return Shipment":
                            begin
                                CopyFilter("Document No.", ReturnShipmentHeader."No.");
                                OnCertificateOfSupplyOnPreDataItemOnAfterFilterForReturnShipmentHeader(CertificateOfSupply, ReturnShipmentHeader);
                                if ReturnShipmentHeader.FindFirst() then
                                    repeat
                                        CertificateOfSupply2.InitFromPurchase(ReturnShipmentHeader);
                                        CertificateOfSupply2.SetRequired(ReturnShipmentHeader."No.")
                                    until ServiceShipmentHeader.Next() = 0;
                            end
                    end
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(PrintLineDetails; PrintLineDetails)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print Line Details';
                    ToolTip = 'Specifies if you want to information from the lines on the shipment document on the certificate of supply.';
                }
                field(CreateCertificatesofSupply; CreateCertificatesofSupply)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Certificates of Supply if Not Already Created';
                    ToolTip = 'Specifies if you want to create a certificate of supply, when you sell goods to a customer in another EU country/region.';
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
        PrintLineDetails := true;
        CreateCertificatesofSupply := false;
    end;

    var
        CompanyInfo: Record "Company Information";
        PrintLineDetails: Boolean;
        CreateCertificatesofSupply: Boolean;

    protected var
        TempServiceShipmentHeader: Record "Service Shipment Header" temporary;
        TempServiceShipmentLine: Record "Service Shipment Line" temporary;

        Quantity_of_the_object_of_the_supply_Lbl: Label '(Quantity of the object of the supply)';
        Standard_commercial_description___in_the_case_of_vehicles__including_vehicle_identification_number_Lbl: Label '(Standard commercial description - in the case of vehicles, including vehicle identification number)';
        Date_the_object_of_the_supply_was_received_in_the_Member_State_of_entry_Lbl: Label '(Date the object of the supply was received in the Member State of entry if the supplying trader transported or dispatched the object of the supply or if the customer dispatched the object of the supply)';
        Date_the_transportation_ended_if_the_customer_transported_the_object_of_the_supply_himself_or_herself_Lbl: Label '(Date the transportation ended if the customer transported the object of the supply himself or herself)';
        in_atLbl: Label 'in/at 1)';
        Member_State_and_place_of_entry_as_part_of_the_transport_or_dispatch_of_the_object_Lbl: Label '(Member State and place of entry as part of the transport or dispatch of the object)';
        Date_of_issue_of_the_certificate_Lbl: Label '(Date of issue of the certificate)';
        Signature_of_the_customer_or_of_the_authorised_representative_as_well_as_the_signatory_s_name_in_capitals_Lbl: Label '(Signature of the customer or of the authorised representative as well as the signatory''s name in capitals)';
        Reference_Document_Lbl: Label 'Reference Document Shipment';
        Vehicle_Registration_No_Lbl: Label 'Vehicle Registration No.';
        Shipment_Method_Lbl: Label 'Shipment Method';
        Certification_of_the_entry_of_the_object_of_an_intra___Community_supply_into_another_Lbl: Label 'Certification of the entry of the object of an intra - Community supply into another ';
        EU_Member_State__Entry_Certificate_Lbl: Label 'EU Member State (Entry Certificate)';
        Name_and_address_of_the_customer_of_the_intra_Community_supply__if_applicable__E_Mail_address_Lbl: Label '(Name and address of the customer of the intra-Community supply, if applicable, Email-address)';
        I_as_the_customer_hereby_certify_my_receipt_the_entry_of_the_following_object_of_an_intra___Community_supplyLbl: Label 'I as the customer hereby certify my receipt/the entry of the following object of an intra - Community supply';
        onLbl: Label 'on';
        receivedLbl: Label 'received/arrived 1)';
        deleteAsAppropriateLbl: Label '1) Delete as appropriate';
        MultipleDocumentsErr: Label 'Multiple Document Types are not allowed.';

    local procedure SetSource(CertificateOfSupply: Record "Certificate of Supply")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSource(CertificateOfSupply, IsHandled);
        if IsHandled then
            exit;

        case CertificateOfSupply."Document Type" of
            CertificateOfSupply."Document Type"::"Sales Shipment":
                begin
                    SalesShipmentHeader.Get(CertificateOfSupply."Document No.");
                    SetSourceSales(SalesShipmentHeader);
                end;
            CertificateOfSupply."Document Type"::"Service Shipment":
                begin
                    ServiceShipmentHeader.Get(CertificateOfSupply."Document No.");
                    SetSourceService(ServiceShipmentHeader);
                end;
            CertificateOfSupply."Document Type"::"Return Shipment":
                begin
                    ReturnShipmentHeader.Get(CertificateOfSupply."Document No.");
                    SetSourcePurchase(ReturnShipmentHeader);
                end;
        end;
    end;

    local procedure SetSourceSales(SalesShipmentHeader: Record "Sales Shipment Header")
    var
        Customer: Record Customer;
    begin
        // bill to details
        Customer.Get(SalesShipmentHeader."Bill-to Customer No.");
        TempServiceShipmentHeader."Bill-to Name" := SalesShipmentHeader."Bill-to Name";
        TempServiceShipmentHeader."Bill-to Customer No." := SalesShipmentHeader."Bill-to Customer No.";
        TempServiceShipmentHeader."Bill-to Address" := SalesShipmentHeader."Bill-to Address";
        TempServiceShipmentHeader."Bill-to Address 2" := SalesShipmentHeader."Bill-to Address 2";
        TempServiceShipmentHeader."Bill-to City" := SalesShipmentHeader."Bill-to City";
        TempServiceShipmentHeader."Bill-to Country/Region Code" := SalesShipmentHeader."Bill-to Country/Region Code";
        TempServiceShipmentHeader."E-Mail" := Customer."E-Mail";
        TempServiceShipmentHeader."No." := SalesShipmentHeader."No.";

        // ship contact details
        TempServiceShipmentHeader."Ship-to Name" := SalesShipmentHeader."Ship-to Name";
        TempServiceShipmentHeader."Ship-to Address" := SalesShipmentHeader."Ship-to Address";
        TempServiceShipmentHeader."Ship-to Address 2" := SalesShipmentHeader."Ship-to Address 2";
        TempServiceShipmentHeader."Ship-to City" := SalesShipmentHeader."Ship-to City";
        TempServiceShipmentHeader."Ship-to Country/Region Code" := SalesShipmentHeader."Ship-to Country/Region Code";

        OnAfterSetSourceSales(SalesShipmentHeader, TempServiceShipmentHeader);
    end;

    local procedure SetSourceService(ServiceShipmentHeader: Record "Service Shipment Header")
    begin
        TempServiceShipmentHeader := ServiceShipmentHeader;
    end;

    local procedure SetSourcePurchase(ReturnShipmentHeader: Record "Return Shipment Header")
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(ReturnShipmentHeader."Buy-from Vendor No.");

        // bill to details
        TempServiceShipmentHeader."Bill-to Name" := ReturnShipmentHeader."Buy-from Vendor Name";
        TempServiceShipmentHeader."Bill-to Address" := ReturnShipmentHeader."Buy-from Address";
        TempServiceShipmentHeader."Bill-to Address 2" := ReturnShipmentHeader."Buy-from Address 2";
        TempServiceShipmentHeader."Bill-to City" := ReturnShipmentHeader."Buy-from City";
        TempServiceShipmentHeader."Bill-to Country/Region Code" := ReturnShipmentHeader."Buy-from Country/Region Code";
        TempServiceShipmentHeader."E-Mail" := Vendor."E-Mail";
        TempServiceShipmentHeader."No." := ReturnShipmentHeader."No.";

        // ship contact details
        TempServiceShipmentHeader."Ship-to Name" := ReturnShipmentHeader."Ship-to Name";
        TempServiceShipmentHeader."Ship-to Address" := ReturnShipmentHeader."Ship-to Address";
        TempServiceShipmentHeader."Ship-to Address 2" := ReturnShipmentHeader."Ship-to Address 2";
        TempServiceShipmentHeader."Ship-to City" := ReturnShipmentHeader."Ship-to City";
        TempServiceShipmentHeader."Ship-to Country/Region Code" := ReturnShipmentHeader."Ship-to Country/Region Code";

        OnAfterSetSourcePurchase(ReturnShipmentHeader, TempServiceShipmentHeader);
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure GetLines(CertificateOfSupply: Record "Certificate of Supply")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetLines(CertificateOfSupply, IsHandled);
        if IsHandled then
            exit;

        case CertificateOfSupply."Document Type" of
            CertificateOfSupply."Document Type"::"Sales Shipment":
                begin
                    SalesShipmentHeader.Get(CertificateOfSupply."Document No.");
                    GetSalesLines(SalesShipmentHeader."No.");
                end;
            CertificateOfSupply."Document Type"::"Service Shipment":
                begin
                    ServiceShipmentHeader.Get(CertificateOfSupply."Document No.");
                    GetServiceLines(ServiceShipmentHeader."No.");
                end;
            CertificateOfSupply."Document Type"::"Return Shipment":
                begin
                    ReturnShipmentHeader.Get(CertificateOfSupply."Document No.");
                    GetPurchaseLines(ReturnShipmentHeader."No.");
                end;
        end;
        TempServiceShipmentLine.FindSet();
    end;

    local procedure GetSalesLines(SalesShipmentHeaderNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeaderNo);
        if SalesShipmentLine.FindSet() then
            repeat
                TempServiceShipmentLine."Line No." := SalesShipmentLine."Line No.";
                TempServiceShipmentLine."No." := SalesShipmentLine."No.";
                TempServiceShipmentLine.Description := SalesShipmentLine.Description;
                TempServiceShipmentLine.Quantity := SalesShipmentLine.Quantity;
                TempServiceShipmentLine."Unit of Measure Code" := SalesShipmentLine."Unit of Measure Code";
                TempServiceShipmentLine."Unit of Measure" := SalesShipmentLine."Unit of Measure";
                TempServiceShipmentLine.Insert();
            until SalesShipmentLine.Next() = 0;
    end;

    local procedure GetServiceLines(ServiceShipmentHeaderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeaderNo);
        if ServiceShipmentLine.FindSet() then
            repeat
                TempServiceShipmentLine := ServiceShipmentLine;
                TempServiceShipmentLine.Insert();
            until ServiceShipmentLine.Next() = 0;
    end;

    local procedure GetPurchaseLines(ReturnShipmentHeaderNo: Code[20])
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        ReturnShipmentLine.SetRange("Document No.", ReturnShipmentHeaderNo);
        if ReturnShipmentLine.FindSet() then
            repeat
                TempServiceShipmentLine."Line No." := ReturnShipmentLine."Line No.";
                TempServiceShipmentLine."No." := ReturnShipmentLine."No.";
                TempServiceShipmentLine.Description := ReturnShipmentLine.Description;
                TempServiceShipmentLine.Quantity := ReturnShipmentLine.Quantity;
                TempServiceShipmentLine."Unit of Measure Code" := ReturnShipmentLine."Unit of Measure Code";
                TempServiceShipmentLine."Unit of Measure" := ReturnShipmentLine."Unit of Measure";
                TempServiceShipmentLine.Insert();
            until ReturnShipmentLine.Next() = 0;
    end;

    local procedure GetLanguageCode(CertificateOfSupply: Record "Certificate of Supply") Result: Code[10]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetLanguageCode(CertificateOfSupply, Result, IsHandled);
        if IsHandled then
            exit;

        case CertificateOfSupply."Document Type" of
            CertificateOfSupply."Document Type"::"Sales Shipment":
                begin
                    SalesShipmentHeader.Get(CertificateOfSupply."Document No.");
                    exit(SalesShipmentHeader."Language Code");
                end;
            CertificateOfSupply."Document Type"::"Service Shipment":
                begin
                    ServiceShipmentHeader.Get(CertificateOfSupply."Document No.");
                    exit(ServiceShipmentHeader."Language Code");
                end;
            CertificateOfSupply."Document Type"::"Return Shipment":
                begin
                    ReturnShipmentHeader.Get(CertificateOfSupply."Document No.");
                    exit(ReturnShipmentHeader."Language Code");
                end;
        end;
    end;

    local procedure GetFormatRegionCode(CertificateOfSupply: Record "Certificate of Supply") Result: Text[80]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetFormatRegion(CertificateOfSupply, Result, IsHandled);
        if IsHandled then
            exit;

        case CertificateOfSupply."Document Type" of
            CertificateOfSupply."Document Type"::"Sales Shipment":
                begin
                    SalesShipmentHeader.Get(CertificateOfSupply."Document No.");
                    exit(SalesShipmentHeader."Format Region");
                end;
            CertificateOfSupply."Document Type"::"Service Shipment":
                begin
                    ServiceShipmentHeader.Get(CertificateOfSupply."Document No.");
                    exit(ServiceShipmentHeader."Format Region");
                end;
            CertificateOfSupply."Document Type"::"Return Shipment":
                begin
                    ReturnShipmentHeader.Get(CertificateOfSupply."Document No.");
                    exit(ReturnShipmentHeader."Format Region");
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLanguageCode(CertificateOfSupply: Record "Certificate of Supply"; var Result: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFormatRegion(CertificateOfSupply: Record "Certificate of Supply"; var Result: Text[80]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetLines(CertificateOfSupply: Record "Certificate of Supply"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetSource(CertificateOfSupply: Record "Certificate of Supply"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCertificateOfSupplyOnPreDataItemOnAfterFilterForSalesShipmentHeader(var CertificateOfSupply: Record "Certificate of Supply"; var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCertificateOfSupplyOnPreDataItemOnAfterFilterForServiceShipmentHeader(var CertificateOfSupply: Record "Certificate of Supply"; var ServiceShipmentHeader: Record "Service Shipment Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCertificateOfSupplyOnPreDataItemOnAfterFilterForReturnShipmentHeader(var CertificateOfSupply: Record "Certificate of Supply"; var ReturnShipmentHeader: Record "Return Shipment Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetSourcePurchase(var ReturnShipmentHeader: Record "Return Shipment Header"; var TempServiceShipmentHeader: Record "Service Shipment Header" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetSourceSales(var SalesShipmentHeader: Record "Sales Shipment Header"; var TempServiceShipmentHeader: Record "Service Shipment Header" temporary)
    begin
    end;
}

