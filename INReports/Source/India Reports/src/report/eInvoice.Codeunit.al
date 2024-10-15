codeunit 18047 "e-Invoice"
{

    trigger OnRun()
    begin
        Initialize();

        if IsInvoice then
            RunSalesInvoice()
        else
            RunSalesCrMemo();


        if DocumentNo <> '' then
            ExportAsJson(DocumentNo)
        else
            Error(RecIsEmptyErr);
    end;

    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        JObject: JsonObject;
        JsonArrayData: JsonArray;
        JsonText: Text;
        DocumentNo: Text[20];
        IsInvoice: Boolean;
        UnRegCusrErr: Label 'E-Invoicing is not applicable for Unregistered Customer.';
        RecIsEmptyErr: Label 'Record variable uninitialized.';
        SalesLinesErr: Label 'E-Invoice allowes only 100 lines per Invoice. Curent transaction is having %1 lines.', Comment = '%1 = Sales Lines count';

    procedure SetSalesInvHeader(SalesInvoiceHeaderBuff: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader := SalesInvoiceHeaderBuff;
        IsInvoice := true;
    end;

    procedure SetCrMemoHeader(SalesCrMemoHeaderBuff: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHeader := SalesCrMemoHeaderBuff;
        IsInvoice := false;
    end;

    local procedure RunSalesInvoice()
    begin
        if not IsInvoice then
            exit;

        if SalesInvoiceHeader."GST Customer Type" in [
            SalesInvoiceHeader."GST Customer Type"::Unregistered,
            SalesInvoiceHeader."GST Customer Type"::" "]
        then
            Error(UnRegCusrErr);

        DocumentNo := SalesInvoiceHeader."No.";
        WriteJsonFileHeader();
        ReadTransactionDetails(SalesInvoiceHeader."GST Customer Type", SalesInvoiceHeader."Ship-to Code");
        ReadDocumentHeaderDetails();
        ReadDocumentSellerDetails();
        ReadDocumentBuyerDetails();
        ReadDocumentShippingDetails();
        ReadDocumentItemList();
        ReadDocumentTotalDetails();
        ReadExpDetails();
    end;

    local procedure RunSalesCrMemo()
    var
        myInt: Integer;
    begin
        if IsInvoice then
            exit;

        if SalesCrMemoHeader."GST Customer Type" in [
            SalesCrMemoHeader."GST Customer Type"::Unregistered,
            SalesCrMemoHeader."GST Customer Type"::" "]
        then
            Error(UnRegCusrErr);

        DocumentNo := SalesCrMemoHeader."No.";
        WriteJsonFileHeader();
        ReadTransactionDetails(SalesCrMemoHeader."GST Customer Type", SalesCrMemoHeader."Ship-to Code");
        ReadDocumentHeaderDetails();
        ReadDocumentSellerDetails();
        ReadDocumentBuyerDetails();
        ReadDocumentShippingDetails();
        ReadDocumentItemList();
        ReadDocumentTotalDetails();
        ReadExpDetails();
    end;

    local procedure Initialize()
    begin
        Clear(JObject);
        Clear(JsonArrayData);
        Clear(JsonText);
    end;

    local procedure WriteJsonFileHeader()
    begin
        JObject.Add('TaxSch', 'GST');
        JObject.Add('Version', '1.0');
        JObject.Add('Irn', '');
        JsonArrayData.Add(JObject);
    end;

    local procedure ReadTransactionDetails(GSTCustType: Enum "GST Customer Type"; ShipToCode: Code[12])
    begin
        Clear(JsonArrayData);
        if IsInvoice then
            ReadInvoiceTransDtls(GSTCustType, ShipToCode)
        else
            ReadCrMemoTransDtls(GSTCustType, ShipToCode);
    end;

    local procedure ReadCrMemoTransDtls(GSTCustType: Enum "GST Customer Type"; ShipToCode: Code[12])
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        catg: Text[3];
        Typ: Text[3];
    begin
        if IsInvoice then
            exit;

        if GSTCustType in [
            SalesCrMemoHeader."GST Customer Type"::Registered,
            SalesCrMemoHeader."GST Customer Type"::Exempted]
        then
            catg := 'B2B'
        else
            catg := 'EXP';

        if ShipToCode <> '' then begin
            SalesCrMemoLine.SetRange("Document No.", DocumentNo);
            if SalesCrMemoLine.FindSet() then
                repeat
                    if SalesCrMemoLine."GST Place of Supply" = SalesCrMemoLine."GST Place of Supply"::"Ship-to Address" then
                        Typ := 'REG'
                    else
                        Typ := 'SHP';
                until SalesCrMemoLine.Next() = 0;
        end else
            Typ := 'REG';

        WriteTransactionDetails(catg, 'RG', Typ, 'false', 'Y', '');
    end;

    local procedure ReadInvoiceTransDtls(GSTCustType: Enum "GST Customer Type"; ShipToCode: Code[12])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        catg: Text[3];
        Typ: Text[3];
    begin
        if not IsInvoice then
            exit;

        if GSTCustType in [
            SalesInvoiceHeader."GST Customer Type"::Registered,
            SalesInvoiceHeader."GST Customer Type"::Exempted]
        then
            catg := 'B2B'
        else
            catg := 'EXP';

        if ShipToCode <> '' then begin
            SalesInvoiceLine.SetRange("Document No.", DocumentNo);
            if SalesInvoiceLine.FindSet() then
                repeat
                    if SalesInvoiceLine."GST Place of Supply" <> SalesInvoiceLine."GST Place of Supply"::"Ship-to Address" then
                        Typ := 'SHP'
                    else
                        Typ := 'REG';
                until SalesInvoiceLine.Next() = 0;
        end else
            Typ := 'REG';

        WriteTransactionDetails(catg, 'RG', Typ, 'false', 'Y', '');
    end;

    local procedure WriteTransactionDetails(
        catg: Text[3];
        RegRev: Text[2];
        Typ: Text[3];
        EcmTrnSel: Text[5];
        EcmTrn: Text[1];
        EcmGstin: Text[15])
    var
        JTranDetails: JsonObject;
    begin
        JTranDetails.Add('Catg', catg);
        JTranDetails.Add('RegRev', RegRev);
        JTranDetails.Add('Typ', Typ);
        JTranDetails.Add('EcmTrnSel', EcmTrnSel);
        JTranDetails.Add('EcmTrn', EcmTrn);
        JTranDetails.Add('EcmGstin', EcmGstin);

        JsonArrayData.Add(JTranDetails);
        JObject.Add('TranDtls', JsonArrayData);
    end;

    local procedure ReadDocumentHeaderDetails()
    var
        Typ: Text[3];
        Dt: Text[10];
        OrgInvNo: Text[16];
    begin
        Clear(JsonArrayData);
        if IsInvoice then begin
            if (SalesInvoiceHeader."Invoice Type" = SalesInvoiceHeader."Invoice Type"::"Debit Note") or
               (SalesInvoiceHeader."Invoice Type" = SalesInvoiceHeader."Invoice Type"::Supplementary)
            then
                Typ := 'DBN'
            else
                Typ := 'INV';
            Dt := Format(SalesInvoiceHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>');
        end else begin
            Typ := 'CRN';
            Dt := Format(SalesCrMemoHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>');
        end;

        OrgInvNo := CopyStr(GetRefInvNo(DocumentNo), 1, 16);
        WriteDocumentHeaderDetails(Typ, CopyStr(DocumentNo, 1, 16), Dt, OrgInvNo);
    end;

    local procedure WriteDocumentHeaderDetails(Typ: Text[3]; No: Text[16]; Dt: Text[10]; OrgInvNo: Text[16])
    var
        JDocumentHeaderDetails: JsonObject;
    begin
        JDocumentHeaderDetails.Add('Typ', Typ);
        JDocumentHeaderDetails.Add('No', No);
        JDocumentHeaderDetails.Add('Dt', Dt);
        JDocumentHeaderDetails.Add('OrgInvNo', OrgInvNo);

        JsonArrayData.Add(JDocumentHeaderDetails);
        JObject.Add('DocDtls', JsonArrayData);
    end;

    local procedure ReadExpDetails()
    begin
        Clear(JsonArrayData);
        if IsInvoice then
            ReadInvoiceExpDtls()
        else
            ReadCrMemoExpDtls();
    end;

    local procedure ReadCrMemoExpDtls()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ExpCat: Text[3];
        WithPay: Text[1];
        ShipBNo: Text[16];
        ShipBDt: Text[10];
        Port: Text[10];
        InvForCur: Decimal;
        ForCur: Text[3];
        CntCode: Text[2];
    begin
        if IsInvoice then
            exit;

        if not (SalesCrMemoHeader."GST Customer Type" in [
            SalesCrMemoHeader."GST Customer Type"::Export,
            SalesCrMemoHeader."GST Customer Type"::"Deemed Export",
            SalesCrMemoHeader."GST Customer Type"::"SEZ Unit",
            SalesCrMemoHeader."GST Customer Type"::"SEZ Development"])
        then
            exit;

        case SalesCrMemoHeader."GST Customer Type" of
            SalesCrMemoHeader."GST Customer Type"::Export:
                ExpCat := 'DIR';
            SalesCrMemoHeader."GST Customer Type"::"Deemed Export":
                ExpCat := 'DEM';
            SalesCrMemoHeader."GST Customer Type"::"SEZ Unit":
                ExpCat := 'SEZ';
            "GST Customer Type"::"SEZ Development":
                ExpCat := 'SED';
        end;

        if SalesCrMemoHeader."GST Without Payment of Duty" then
            WithPay := 'N'
        else
            WithPay := 'Y';

        ShipBNo := CopyStr(SalesCrMemoHeader."Bill Of Export No.", 1, 16);
        ShipBDt := Format(SalesCrMemoHeader."Bill Of Export Date", 0, '<Year4>-<Month,2>-<Day,2>');
        Port := SalesCrMemoHeader."Exit Point";

        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.FindSet() then
            repeat
                InvForCur := InvForCur + SalesCrMemoLine.Amount;
            until SalesCrMemoLine.Next() = 0;

        ForCur := CopyStr(SalesCrMemoHeader."Currency Code", 1, 3);
        CntCode := CopyStr(SalesCrMemoHeader."Bill-to Country/Region Code", 1, 2);

        WriteExpDtls(ExpCat, WithPay, ShipBNo, ShipBDt, Port, InvForCur, ForCur, CntCode);
    end;

    local procedure ReadInvoiceExpDtls()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        ExpCat: Text[3];
        WithPay: Text[1];
        ShipBNo: Text[16];
        ShipBDt: Text[10];
        Port: Text[10];
        InvForCur: Decimal;
        ForCur: Text[3];
        CntCode: Text[2];
    begin
        if not IsInvoice then
            exit;

        if not (SalesInvoiceHeader."GST Customer Type" in [
            SalesInvoiceHeader."GST Customer Type"::Export,
            SalesInvoiceHeader."GST Customer Type"::"Deemed Export",
            SalesInvoiceHeader."GST Customer Type"::"SEZ Unit",
            SalesInvoiceHeader."GST Customer Type"::"SEZ Development"])
        then
            exit;

        case SalesInvoiceHeader."GST Customer Type" of
            SalesInvoiceHeader."GST Customer Type"::Export:
                ExpCat := 'DIR';
            SalesInvoiceHeader."GST Customer Type"::"Deemed Export":
                ExpCat := 'DEM';
            SalesInvoiceHeader."GST Customer Type"::"SEZ Unit":
                ExpCat := 'SEZ';
            SalesInvoiceHeader."GST Customer Type"::"SEZ Development":
                ExpCat := 'SED';
        end;

        if SalesInvoiceHeader."GST Without Payment of Duty" then
            WithPay := 'N'
        else
            WithPay := 'Y';

        ShipBNo := CopyStr(SalesInvoiceHeader."Bill Of Export No.", 1, 16);
        ShipBDt := Format(SalesInvoiceHeader."Bill Of Export Date", 0, '<Year4>-<Month,2>-<Day,2>');
        Port := SalesInvoiceHeader."Exit Point";

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                InvForCur := InvForCur + SalesInvoiceLine.Amount;
            until SalesInvoiceLine.Next() = 0;

        ForCur := CopyStr(SalesInvoiceHeader."Currency Code", 1, 3);
        CntCode := CopyStr(SalesInvoiceHeader."Bill-to Country/Region Code", 1, 2);

        WriteExpDtls(ExpCat, WithPay, ShipBNo, ShipBDt, Port, InvForCur, ForCur, CntCode);
    end;

    local procedure WriteExpDtls(
        ExpCat: Text[3];
        WithPay: Text[1];
        ShipBNo: Text[16];
        ShipBDt: Text[10];
        Port: Text[10];
        InvForCur: Decimal;
        ForCur: Text[3];
        CntCode: Text[2])
    var
        JExpDetails: JsonObject;
    begin
        JExpDetails.Add('ExpCat', ExpCat);
        JExpDetails.Add('WithPay', WithPay);
        JExpDetails.Add('ShipBNo', ShipBNo);
        JExpDetails.Add('ShipBDt', ShipBDt);
        JExpDetails.Add('Port', Port);
        JExpDetails.Add('InvForCur', InvForCur);
        JExpDetails.Add('ForCur', ForCur);
        JExpDetails.Add('CntCode', CntCode);

        JsonArrayData.Add(JExpDetails);
        JObject.Add('ExpDtls', JsonArrayData);
    end;

    local procedure ReadDocumentSellerDetails()
    var
        CompanyInformationBuff: Record "Company Information";
        LocationBuff: Record "Location";
        StateBuff: Record "State";
        Gstin: Text[20];
        TrdNm: Text[100];
        Bno: Text[100];
        Bnm: Text[100];
        Flno: Text[60];
        Loc: Text[60];
        Dst: Text[60];
        Pin: Text[6];
        Stcd: Text[10];
        Ph: Text[10];
        Em: Text[50];
    begin
        Clear(JsonArrayData);
        if IsInvoice then begin
            Gstin := SalesInvoiceHeader."Location GST Reg. No.";
            LocationBuff.Get(SalesInvoiceHeader."Location Code");
        end else begin
            Gstin := SalesCrMemoHeader."Location GST Reg. No.";
            LocationBuff.Get(SalesCrMemoHeader."Location Code");
        end;

        CompanyInformationBuff.Get();
        TrdNm := CompanyInformationBuff.Name;
        Bno := LocationBuff.Address;
        Bnm := LocationBuff."Address 2";
        Flno := '';
        Loc := '';
        Dst := LocationBuff.City;
        Pin := CopyStr(LocationBuff."Post Code", 1, 6);
        StateBuff.Get(LocationBuff."State Code");
        Stcd := StateBuff."State Code (GST Reg. No.)";
        Ph := CopyStr(LocationBuff."Phone No.", 1, 10);
        Em := CopyStr(LocationBuff."E-Mail", 1, 50);

        WriteSellerDtls(Gstin, TrdNm, Bno, Bnm, Flno, Loc, Dst, Pin, Stcd, Ph, Em);
    end;

    local procedure WriteSellerDtls(
        Gstin: Text[20];
        TrdNm: Text[100];
        Bno: Text[100];
        Bnm: Text[100];
        Flno: Text[60];
        Loc: Text[60];
        Dst: Text[60];
        Pin: Text[6];
        Stcd: Text[10];
        Ph: Text[10];
        Em: Text[50])
    var
        JSellerDetails: JsonObject;
    begin
        JSellerDetails.Add('Gstin', Gstin);
        JSellerDetails.Add('TrdNm', TrdNm);
        JSellerDetails.Add('Bno', Bno);
        JSellerDetails.Add('Bnm', Bnm);
        JSellerDetails.Add('Flno', Flno);
        JSellerDetails.Add('Loc', Loc);
        JSellerDetails.Add('Dst', Dst);
        JSellerDetails.Add('Pin', Pin);
        JSellerDetails.Add('Stcd', Stcd);
        JSellerDetails.Add('Ph', Ph);
        JSellerDetails.Add('Em', Em);

        JsonArrayData.Add(JSellerDetails);
        JObject.Add('SellerDtls', JsonArrayData);
    end;

    local procedure ReadDocumentBuyerDetails()
    begin
        Clear(JsonArrayData);
        if IsInvoice then
            ReadInvoiceBuyerDetails()
        else
            ReadCrMemoBuyerDetails();
    end;

    local procedure ReadInvoiceBuyerDetails()
    var
        Contact: Record Contact;
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ShipToAddr: Record "Ship-to Address";
        StateBuff: Record State;
        Gstin: Text[20];
        TrdNm: Text[100];
        Bno: Text[100];
        Bnm: Text[100];
        Flno: Text[60];
        Loc: Text[60];
        Dst: Text[60];
        Pin: Text[6];
        Stcd: Text[10];
        Ph: Text[10];
        Em: Text[50];
    begin
        Gstin := SalesInvoiceHeader."Customer GST Reg. No.";
        TrdNm := SalesInvoiceHeader."Bill-to Name";
        Bno := SalesInvoiceHeader."Bill-to Address";
        Bnm := SalesInvoiceHeader."Bill-to Address 2";
        Flno := '';
        Loc := '';
        Dst := SalesInvoiceHeader."Bill-to City";
        Pin := CopyStr(SalesInvoiceHeader."Bill-to Post Code", 1, 6);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindFirst() then
            case SalesInvoiceLine."GST Place of Supply" of
                SalesInvoiceLine."GST Place of Supply"::"Bill-to Address":
                    begin
                        if not (SalesInvoiceHeader."GST Customer Type" = SalesInvoiceHeader."GST Customer Type"::Export) then begin
                            StateBuff.Get(SalesInvoiceHeader."GST Bill-to State Code");
                            Stcd := StateBuff."State Code for eTDS/TCS";
                        end else
                            Stcd := '';
                        if Contact.Get(SalesInvoiceHeader."Bill-to Contact No.") then begin
                            Ph := CopyStr(Contact."Phone No.", 1, 10);
                            Em := CopyStr(Contact."E-Mail", 1, 50);
                        end else begin
                            Ph := '';
                            Em := '';
                        end;
                    end;
                SalesInvoiceLine."GST Place of Supply"::"Ship-to Address":
                    begin
                        if not (SalesInvoiceHeader."GST Customer Type" = SalesInvoiceHeader."GST Customer Type"::Export) then begin
                            StateBuff.Get(SalesInvoiceHeader."GST Ship-to State Code");
                            Stcd := StateBuff."State Code for eTDS/TCS";
                        end else
                            Stcd := '';
                        if ShipToAddr.Get(SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."Ship-to Code") then begin
                            Ph := CopyStr(ShipToAddr."Phone No.", 1, 10);
                            Em := CopyStr(ShipToAddr."E-Mail", 1, 50);
                        end else begin
                            Ph := '';
                            Em := '';
                        end;
                    end;
                else begin
                        Stcd := '';
                        Ph := '';
                        Em := '';
                    end;
            end;
        WriteBuyerDtls(Gstin, TrdNm, Bno, Bnm, Flno, Loc, Dst, Pin, Stcd, Ph, Em);
    end;

    local procedure ReadCrMemoBuyerDetails()
    var
        Contact: Record Contact;
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ShipToAddr: Record "Ship-to Address";
        StateBuff: Record State;
        Gstin: Text[20];
        TrdNm: Text[100];
        Bno: Text[100];
        Bnm: Text[100];
        Flno: Text[60];
        Loc: Text[60];
        Dst: Text[60];
        Pin: Text[6];
        Stcd: Text[10];
        Ph: Text[10];
        Em: Text[50];
    begin
        Gstin := SalesCrMemoHeader."Customer GST Reg. No.";
        TrdNm := SalesCrMemoHeader."Bill-to Name";
        Bno := SalesCrMemoHeader."Bill-to Address";
        Bnm := SalesCrMemoHeader."Bill-to Address 2";
        Flno := '';
        Loc := '';
        Dst := SalesCrMemoHeader."Bill-to City";
        Pin := CopyStr(SalesCrMemoHeader."Bill-to Post Code", 1, 6);
        Stcd := '';
        Ph := '';
        Em := '';

        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.FindFirst() then
            case SalesCrMemoLine."GST Place of Supply" of
                SalesCrMemoLine."GST Place of Supply"::"Bill-to Address":
                    begin
                        if not (SalesCrMemoHeader."GST Customer Type" = SalesCrMemoHeader."GST Customer Type"::Export) then begin
                            StateBuff.Get(SalesCrMemoHeader."GST Bill-to State Code");
                            Stcd := StateBuff."State Code for eTDS/TCS";
                        end;

                        if Contact.Get(SalesCrMemoHeader."Bill-to Contact No.") then begin
                            Ph := CopyStr(Contact."Phone No.", 1, 10);
                            Em := CopyStr(Contact."E-Mail", 1, 50);
                        end;
                    end;
                SalesCrMemoLine."GST Place of Supply"::"Ship-to Address":
                    begin
                        if not (SalesCrMemoHeader."GST Customer Type" = SalesCrMemoHeader."GST Customer Type"::Export) then begin
                            StateBuff.Get(SalesCrMemoHeader."GST Ship-to State Code");
                            Stcd := StateBuff."State Code for eTDS/TCS";
                        end;

                        if ShipToAddr.Get(SalesCrMemoHeader."Sell-to Customer No.", SalesCrMemoHeader."Ship-to Code") then begin
                            Ph := CopyStr(ShipToAddr."Phone No.", 1, 10);
                            Em := CopyStr(ShipToAddr."E-Mail", 1, 50);
                        end;
                    end;
            end;

        WriteBuyerDtls(Gstin, TrdNm, Bno, Bnm, Flno, Loc, Dst, Pin, Stcd, Ph, Em);
    end;

    local procedure WriteBuyerDtls(
        Gstin: Text[20];
        TrdNm: Text[100];
        Bno: Text[100];
        Bnm: Text[100];
        Flno: Text[60];
        Loc: Text[60];
        Dst: Text[60];
        Pin: Text[6];
        Stcd: Text[10];
        Ph: Text[10];
        Em: Text[50])
    var
        JBuyerDetails: JsonObject;
    begin
        JBuyerDetails.Add('Gstin', Gstin);
        JBuyerDetails.Add('TrdNm', TrdNm);
        JBuyerDetails.Add('Bno', Bno);
        JBuyerDetails.Add('Bnm', Bnm);
        JBuyerDetails.Add('Flno', Flno);
        JBuyerDetails.Add('Loc', Loc);
        JBuyerDetails.Add('Dst', Dst);
        JBuyerDetails.Add('Pin', Pin);
        JBuyerDetails.Add('Stcd', Stcd);
        JBuyerDetails.Add('Ph', Ph);
        JBuyerDetails.Add('Em', Em);

        JsonArrayData.Add(JBuyerDetails);
        JObject.Add('BuyerDtls', JsonArrayData);
    end;

    local procedure ReadDocumentShippingDetails()
    var
        ShipToAddr: Record "Ship-to Address";
        StateBuff: Record State;
        Gstin: Text[20];
        TrdNm: Text[100];
        Bno: Text[100];
        Bnm: Text[100];
        Flno: Text[60];
        Loc: Text[60];
        Dst: Text[60];
        Pin: Text[6];
        Stcd: Text[10];
        Ph: Text[10];
        Em: Text[50];
    begin
        Clear(JsonArrayData);
        if IsInvoice and (SalesInvoiceHeader."Ship-to Code" <> '') then begin
            ShipToAddr.Get(SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."Ship-to Code");
            StateBuff.Get(SalesInvoiceHeader."GST Ship-to State Code");
            TrdNm := SalesInvoiceHeader."Ship-to Name";
            Bno := SalesInvoiceHeader."Ship-to Address";
            Bnm := SalesInvoiceHeader."Ship-to Address 2";
            Dst := SalesInvoiceHeader."Ship-to City";
            Pin := CopyStr(SalesInvoiceHeader."Ship-to Post Code", 1, 6);
        end else
            if SalesCrMemoHeader."Ship-to Code" <> '' then begin
                ShipToAddr.Get(SalesCrMemoHeader."Sell-to Customer No.", SalesCrMemoHeader."Ship-to Code");
                StateBuff.Get(SalesCrMemoHeader."GST Ship-to State Code");
                TrdNm := SalesCrMemoHeader."Ship-to Name";
                Bno := SalesCrMemoHeader."Ship-to Address";
                Bnm := SalesCrMemoHeader."Ship-to Address 2";
                Dst := SalesCrMemoHeader."Ship-to City";
                Pin := CopyStr(SalesCrMemoHeader."Ship-to Post Code", 1, 6);
            end;

        Gstin := ShipToAddr."GST Registration No.";
        Flno := '';
        Loc := '';
        Stcd := StateBuff."State Code for eTDS/TCS";
        Ph := CopyStr(ShipToAddr."Phone No.", 1, 10);
        Em := CopyStr(ShipToAddr."E-Mail", 1, 50);
        WriteShipDtls(Gstin, TrdNm, Bno, Bnm, Flno, Loc, Dst, Pin, Stcd, Ph, Em);
    end;

    local procedure WriteShipDtls(
        Gstin: Text[20];
        TrdNm: Text[100];
        Bno: Text[100];
        Bnm: Text[100];
        Flno: Text[60];
        Loc: Text[60];
        Dst: Text[60];
        Pin: Text[6];
        Stcd: Text[10];
        Ph: Text[10];
        Em: Text[50])
    var
        JShippingDetails: JsonObject;
    begin
        JShippingDetails.Add('Gstin', Gstin);
        JShippingDetails.Add('TrdNm', TrdNm);
        JShippingDetails.Add('Bno', Bno);
        JShippingDetails.Add('Bnm', Bnm);
        JShippingDetails.Add('Flno', Flno);
        JShippingDetails.Add('Loc', Loc);
        JShippingDetails.Add('Dst', Dst);
        JShippingDetails.Add('Pin', Pin);
        JShippingDetails.Add('Stcd', Stcd);
        JShippingDetails.Add('Ph', Ph);
        JShippingDetails.Add('Em', Em);

        JsonArrayData.Add(JShippingDetails);
        JObject.Add('ShipDtls', JsonArrayData);
    end;

    local procedure ReadDocumentTotalDetails()
    var
        AssVal: Decimal;
        CgstVal: Decimal;
        SgstVal: Decimal;
        IgstVal: Decimal;
        CesVal: Decimal;
        StCesVal: Decimal;
        CesNonAdval: Decimal;
        Disc: Decimal;
        OthChrg: Decimal;
        TotInvVal: Decimal;
    begin
        Clear(JsonArrayData);
        GetGSTVal(AssVal, CgstVal, SgstVal, IgstVal, CesVal, StCesVal, CesNonAdval, Disc, OthChrg, TotInvVal);
        WriteDocumentTotalDetails(AssVal, CgstVal, SgstVal, IgstVal, CesVal, StCesVal, CesNonAdval, Disc, OthChrg, TotInvVal);
    end;

    local procedure WriteDocumentTotalDetails(
        Assval: Decimal;
        CgstVal: Decimal;
        SgstVAl: Decimal;
        IgstVal: Decimal;
        CesVal: Decimal;
        StCesVal: Decimal;
        CesNonAdVal: Decimal;
        Disc: Decimal;
        OthChrg: Decimal;
        TotInvVal: Decimal)
    var
        JDocTotalDetails: JsonObject;
    begin
        JDocTotalDetails.Add('Assval', Assval);
        JDocTotalDetails.Add('CgstVal', CgstVal);
        JDocTotalDetails.Add('SgstVAl', SgstVAl);
        JDocTotalDetails.Add('IgstVal', IgstVal);
        JDocTotalDetails.Add('CesVal', CesVal);
        JDocTotalDetails.Add('StCesVal', StCesVal);
        JDocTotalDetails.Add('CesNonAdVal', CesNonAdVal);
        JDocTotalDetails.Add('Disc', Disc);
        JDocTotalDetails.Add('OthChrg', OthChrg);
        JDocTotalDetails.Add('TotInvVal', TotInvVal);

        JsonArrayData.Add(JDocTotalDetails);
        JObject.Add('ValDtls', JsonArrayData);
    end;

    local procedure ReadDocumentItemList()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        AssAmt: Decimal;
        CgstRt: Decimal;
        SgstRt: Decimal;
        IgstRt: Decimal;
        CesRt: Decimal;
        CesNonAdval: Decimal;
        StateCes: Decimal;
        FreeQty: Decimal;
        CgstVal: Decimal;
        SgstVal: Decimal;
        IgstVal: Decimal;
    begin
        Clear(JsonArrayData);
        if IsInvoice then begin
            SalesInvoiceLine.SetRange("Document No.", DocumentNo);
            if SalesInvoiceLine.FindSet() then begin
                if SalesInvoiceLine.Count > 100 then
                    Error(SalesLinesErr, SalesInvoiceLine.Count);
                repeat
                    if SalesInvoiceLine."GST Assessable Value (LCY)" <> 0 then
                        AssAmt := SalesInvoiceLine."GST Assessable Value (LCY)"
                    else
                        AssAmt := SalesInvoiceLine.Amount;

                    FreeQty := 0;
                    GetGSTCompRate(
                        SalesInvoiceLine."Document No.",
                        SalesInvoiceLine."Line No.",
                        CgstRt,
                        SgstRt,
                        IgstRt,
                        CesRt,
                        CesNonAdval,
                        StateCes);

                    GetGSTValForLine(SalesInvoiceLine."Line No.", CgstVal, SgstVal, IgstVal);
                    WriteItem(
                      SalesInvoiceLine.Description + SalesInvoiceLine."Description 2", '',
                      SalesInvoiceLine."HSN/SAC Code", '',
                      SalesInvoiceLine.Quantity, FreeQty,
                      CopyStr(SalesInvoiceLine."Unit of Measure Code", 1, 3),
                      SalesInvoiceLine."Unit Price",
                      SalesInvoiceLine."Line Amount" + SalesInvoiceLine."Line Discount Amount",
                      SalesInvoiceLine."Line Discount Amount", 0,
                      AssAmt, CgstRt, SgstRt, IgstRt, CesRt, CesNonAdval, StateCes,
                      AssAmt + CgstVal + SgstVal + IgstVal);
                until SalesInvoiceLine.Next() = 0;
            end;

            JObject.Add('ItemList', JsonArrayData);
        end else begin
            SalesCrMemoLine.SetRange("Document No.", DocumentNo);
            if SalesCrMemoLine.FindSet() then begin
                if SalesCrMemoLine.Count > 100 then
                    Error(SalesLinesErr, SalesCrMemoLine.Count);

                repeat
                    if SalesCrMemoLine."GST Assessable Value (LCY)" <> 0 then
                        AssAmt := SalesCrMemoLine."GST Assessable Value (LCY)"
                    else
                        AssAmt := SalesCrMemoLine.Amount;

                    FreeQty := 0;
                    GetGSTCompRate(
                        SalesCrMemoLine."Document No.",
                        SalesCrMemoLine."Line No.",
                        CgstRt,
                        SgstRt,
                        IgstRt,
                        CesRt,
                        CesNonAdval,
                        StateCes);

                    GetGSTValForLine(SalesCrMemoLine."Line No.", CgstVal, SgstVal, IgstVal);
                    WriteItem(
                      SalesCrMemoLine.Description + SalesCrMemoLine."Description 2", '',
                      SalesCrMemoLine."HSN/SAC Code", '',
                      SalesCrMemoLine.Quantity, FreeQty,
                      CopyStr(SalesCrMemoLine."Unit of Measure Code", 1, 3),
                      SalesCrMemoLine."Unit Price",
                      SalesCrMemoLine."Line Amount" + SalesCrMemoLine."Line Discount Amount",
                      SalesCrMemoLine."Line Discount Amount", 0,
                      AssAmt, CgstRt, SgstRt, IgstRt, CesRt, CesNonAdval, StateCes,
                      AssAmt + CgstVal + SgstVal + IgstVal);
                until SalesCrMemoLine.Next() = 0;
            end;

            JObject.Add('ItemList', JsonArrayData);
        end;
    end;

    local procedure WriteItem(
        PrdNm: Text;
        PrdDesc: Text;
        HsnCd: Text[10];
        Barcde: Text[30];
        Qty: Decimal;
        FreeQty: Decimal;
        Unit: Text[3];
        UnitPrice: Decimal;
        TotAmt: Decimal;
        Discount: Decimal;
        OthChrg: Decimal;
        AssAmt: Decimal;
        CgstRt: Decimal;
        SgstRt: Decimal;
        IgstRt: Decimal;
        CesRt: Decimal;
        CesNonAdval: Decimal;
        StateCes: Decimal;
        TotItemVal: Decimal)
    var
        JItem: JsonObject;
    begin
        JItem.Add('PrdNm', PrdNm);
        JItem.Add('PrdDesc', PrdDesc);
        JItem.Add('HsnCd', HsnCd);
        JItem.Add('Barcde', Barcde);
        JItem.Add('Qty', Qty);
        JItem.Add('FreeQty', FreeQty);
        JItem.Add('Unit', Unit);
        JItem.Add('UnitPrice', UnitPrice);
        JItem.Add('TotAmt', TotAmt);
        JItem.Add('Discount', Discount);
        JItem.Add('OthChrg', OthChrg);
        JItem.Add('AssAmt', AssAmt);
        JItem.Add('CgstRt', CgstRt);
        JItem.Add('SgstRt', SgstRt);
        JItem.Add('IgstRt', IgstRt);
        JItem.Add('CesRt', CesRt);
        JItem.Add('CesNonAdval', CesNonAdval);
        JItem.Add('StateCes', StateCes);
        JItem.Add('TotItemVal', TotItemVal);

        JsonArrayData.Add(JItem);
    end;

    local procedure ExportAsJson(FileName: Text[20])
    var
        TempBlob: Codeunit "Temp Blob";
        ToFile: Variant;
        InStream: InStream;
        OutStream: OutStream;
    begin
        JObject.WriteTo(JsonText);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(JsonText);
        ToFile := FileName + '.json';
        TempBlob.CreateInStream(InStream);
        DownloadFromStream(InStream, 'e-Invoice', '', '', ToFile);
    end;

    local procedure GetRefInvNo(DocNo: Code[20]) RefInvNo: Code[20]
    var
        ReferenceInvoiceNo: Record "Reference Invoice No.";
    begin
        ReferenceInvoiceNo.SetRange("Document No.", DocNo);
        if ReferenceInvoiceNo.FindFirst() then
            RefInvNo := ReferenceInvoiceNo."Reference Invoice Nos."
        else
            RefInvNo := '';
    end;

    local procedure GetGSTCompRate(
        DocNo: Code[20];
        LineNo: Integer;
        var CgstRt: Decimal;
        var SgstRt: Decimal;
        var IgstRt: Decimal;
        var CesRt: Decimal;
        var CesNonAdval: Decimal;
        var StateCes: Decimal)
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        GSTComponent: Record "GST Component";
    begin
        DetailedGSTLedgerEntry.SetRange("Document No.", DocNo);
        DetailedGSTLedgerEntry.SetRange("Document Line No.", LineNo);

        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'CGST');
        if DetailedGSTLedgerEntry.FindFirst() then
            CgstRt := DetailedGSTLedgerEntry."GST %"
        else
            CgstRt := 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'SGST');
        if DetailedGSTLedgerEntry.FindFirst() then
            SgstRt := DetailedGSTLedgerEntry."GST %"
        else
            SgstRt := 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'IGST');
        if DetailedGSTLedgerEntry.FindFirst() then
            IgstRt := DetailedGSTLedgerEntry."GST %"
        else
            IgstRt := 0;

        CesRt := 0;
        CesNonAdval := 0;
        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'CESS');
        if DetailedGSTLedgerEntry.FindFirst() then
            if DetailedGSTLedgerEntry."GST %" > 0 then
                CesRt := DetailedGSTLedgerEntry."GST %"
            else
                CesNonAdval := Abs(DetailedGSTLedgerEntry."GST Amount");

        StateCes := 0;
        DetailedGSTLedgerEntry.SetRange("GST Component Code");
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                if not (DetailedGSTLedgerEntry."GST Component Code" in ['CGST', 'SGST', 'IGST', 'CESS'])
                then
                    if GSTComponent.Get(DetailedGSTLedgerEntry."GST Component Code") then
                        if GSTComponent."Exclude from Reports" then
                            StateCes := DetailedGSTLedgerEntry."GST %";
            until DetailedGSTLedgerEntry.Next() = 0;
    end;

    local procedure GetGSTVal(
        var AssVal: Decimal;
        var CgstVal: Decimal;
        var SgstVal: Decimal;
        var IgstVal: Decimal;
        var CesVal: Decimal;
        var StCesVal: Decimal;
        var CesNonAdval: Decimal;
        var Disc: Decimal;
        var OthChrg: Decimal;
        var TotInvVal: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        GSTLedgerEntry: Record "GST Ledger Entry";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GSTComponent: Record "GST Component";
        TotGSTAmt: Decimal;
    begin
        GSTLedgerEntry.SetRange("Document No.", DocumentNo);

        GSTLedgerEntry.SetRange("GST Component Code", 'CGST');
        if GSTLedgerEntry.FindSet() then
            repeat
                CgstVal += Abs(GSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0
        else
            CgstVal := 0;

        GSTLedgerEntry.SetRange("GST Component Code", 'SGST');
        if GSTLedgerEntry.FindSet() then
            repeat
                SgstVal += Abs(GSTLedgerEntry."GST Amount")
            until GSTLedgerEntry.Next() = 0
        else
            SgstVal := 0;

        GSTLedgerEntry.SetRange("GST Component Code", 'IGST');
        if GSTLedgerEntry.FindSet() then
            repeat
                IgstVal += Abs(GSTLedgerEntry."GST Amount")
            until GSTLedgerEntry.Next() = 0
        else
            IgstVal := 0;

        CesVal := 0;
        CesNonAdval := 0;

        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'CESS');
        if DetailedGSTLedgerEntry.FindFirst() then
            repeat
                if DetailedGSTLedgerEntry."GST %" > 0 then
                    CesVal += Abs(DetailedGSTLedgerEntry."GST Amount")
                else
                    CesNonAdval += Abs(DetailedGSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0;

        GSTLedgerEntry.SetFilter("GST Component Code", '<>CGST|<>SGST|<>IGST|<>CESS');
        if GSTLedgerEntry.FindSet() then
            repeat
                if GSTComponent.Get(GSTLedgerEntry."GST Component Code") then
                    if GSTComponent."Exclude from Reports" then
                        StCesVal += Abs(GSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0;

        if IsInvoice then begin
            SalesInvoiceLine.SetRange("Document No.", DocumentNo);
            if SalesInvoiceLine.FindSet() then
                repeat
                    AssVal += SalesInvoiceLine.Amount;
                    Disc += SalesInvoiceLine."Inv. Discount Amount";
                until SalesInvoiceLine.Next() = 0;
            TotGSTAmt := CgstVal + SgstVal + IgstVal + CesVal + CesNonAdval + StCesVal;

            AssVal := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  WorkDate(), SalesInvoiceHeader."Currency Code", AssVal, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
            TotGSTAmt := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  WorkDate(), SalesInvoiceHeader."Currency Code", TotGSTAmt, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
            Disc := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  WorkDate(), SalesInvoiceHeader."Currency Code", Disc, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
        end else begin
            SalesCrMemoLine.SetRange("Document No.", DocumentNo);
            if SalesCrMemoLine.FindSet() then begin
                repeat
                    AssVal += SalesCrMemoLine.Amount;
                    Disc += SalesCrMemoLine."Inv. Discount Amount";
                until SalesCrMemoLine.Next() = 0;
                TotGSTAmt := CgstVal + SgstVal + IgstVal + CesVal + CesNonAdval + StCesVal;
            end;

            AssVal := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    WorkDate(),
                    SalesCrMemoHeader."Currency Code",
                    AssVal,
                    SalesCrMemoHeader."Currency Factor"),
                0.01,
                '=');

            TotGSTAmt := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    WorkDate(),
                    SalesCrMemoHeader."Currency Code",
                    TotGSTAmt,
                    SalesCrMemoHeader."Currency Factor"),
                0.01,
                '=');

            Disc := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    WorkDate(),
                    SalesCrMemoHeader."Currency Code",
                    Disc,
                    SalesCrMemoHeader."Currency Factor"),
                0.01,
                '=');
        end;

        CustLedgerEntry.SetCurrentKey("Document No.");
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        if IsInvoice then begin
            CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
            CustLedgerEntry.SetRange("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
        end else begin
            CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
            CustLedgerEntry.SetRange("Customer No.", SalesCrMemoHeader."Bill-to Customer No.");
        end;

        if CustLedgerEntry.FindFirst() then begin
            CustLedgerEntry.CalcFields("Amount (LCY)");
            TotInvVal := Abs(CustLedgerEntry."Amount (LCY)");
        end;

        OthChrg := 0;
    end;

    local procedure GetGSTValForLine(
        DocumentLineNo: Integer;
        var CgstLineVal: Decimal;
        var SgstLineVal: Decimal;
        var IgstLineVal: Decimal)
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        CgstLineVal := 0;
        SgstLineVal := 0;
        IgstLineVal := 0;

        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SetRange("Document Line No.", DocumentLineNo);
        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'CGST');
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                CgstLineVal += Abs(DetailedGSTLedgerEntry."GST Amount");
            until DetailedGSTLedgerEntry.Next() = 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'SGST');
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                SgstLineVal += Abs(DetailedGSTLedgerEntry."GST Amount")
            until DetailedGSTLedgerEntry.Next() = 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'IGST');
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                IgstLineVal += Abs(DetailedGSTLedgerEntry."GST Amount")
            until DetailedGSTLedgerEntry.Next() = 0;
    end;
}