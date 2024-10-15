codeunit 18838 "TCS Sales Validations"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterValidateEvent', 'No.', false, false)]
    local procedure AssignNOC(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; CurrFieldNo: Integer)
    var
        AllowedNoc: Record "Allowed Noc";
    begin
        if (Rec."Document Type" in [Rec."Document Type"::Quote, Rec."Document Type"::Order, Rec."Document Type"::Invoice,
         Rec."Document Type"::"Return Order", Rec."Document Type"::"Credit Memo"]) then begin
            AllowedNoc.Reset();
            AllowedNoc.SetRange("customer No.", Rec."Sell-to Customer No.");
            AllowedNoc.SetRange(AllowedNoc."Default Noc", true);
            if AllowedNoc.findfirst() then
                Rec.Validate("TCS Nature of Collection", AllowedNoc."TCS Nature of Collection")
            else
                Rec.Validate("TCS Nature of Collection", '');
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterInitHeaderDefaults', '', false, false)]
    local procedure AssesseeCodeSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        if SalesLine."Document Type" in [SalesLine."Document Type"::Quote, SalesLine."Document Type"::Order, SalesLine."Document Type"::Invoice,
        SalesLine."Document Type"::"Return Order", SalesLine."Document Type"::"Credit Memo"] then
            SalesLine."Assessee Code" := SalesHeader."Assessee Code"
        else
            SalesLine."Assessee Code" := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterCheckSellToCust', '', false, false)]
    local procedure AssesseeCode(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
        if SalesHeader."Document Type" in [SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice,
         SalesHeader."Document Type"::"Return Order", SalesHeader."Document Type"::"Credit Memo"] then
            SalesHeader."Assessee Code" := Customer."Assessee Code"
        else
            SalesHeader."Assessee Code" := '';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostCustomerEntry', '', false, false)]
    local procedure PostCustEntry(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line")
    var
        SalesLine: Record "Sales Line";
        CompanyInfo: Record "Company Information";
        Location: Record Location;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindFirst() then
            GenJnlLine."TCS Nature of Collection" := SalesLine."TCS Nature of Collection";
        IF GenJnlLine."Location Code" <> '' THEN BEGIN
            Location.GET(GenJnlLine."Location Code");
            IF Location."T.C.A.N. No." <> '' THEN
                GenJnlLine."T.C.A.N. No." := Location."T.C.A.N. No."
        END ELSE BEGIN
            CompanyInfo.GET();
            GenJnlLine."T.C.A.N. No." := CompanyInfo."T.C.A.N. No.";
        END;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterValidateEvent', 'TCS Nature of Collection', false, false)]
    local procedure TCSNOCValidation(var Rec: Record "Sales Line"; var xRec: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        TCSNatureOfCollection: Record "TCS Nature Of Collection";
        AllowedNOC: Record "Allowed NOC";
        NOCTypeErr: Label '%1 does not exist in table %2.', Comment = '%1=TCS Nature of Collection., %2=The Table Name.';
        NOCNotDefinedErr: Label 'TCS Nature of Collection %1 is not defined for Customer no. %2.', Comment = '%1= TCS Nature of Collection, %2=Customer No.';
    begin
        if Rec."TCS Nature of Collection" <> '' then begin
            if not TCSNatureOfCollection.Get(Rec."TCS Nature of Collection") then
                Error(NOCTypeErr, Rec."TCS Nature of Collection", TCSNatureOfCollection.TableCaption());

            if not AllowedNOC.Get(Rec."Bill-to Customer No.", Rec."TCS Nature of Collection") then
                Error(NOCNotDefinedErr, Rec."TCS Nature of Collection", Rec."Bill-to Customer No.");

            SalesHeader.get(Rec."Document Type", Rec."Document No.");
            if SalesHeader."Applies-to Doc. No." <> '' then
                SalesHeader.Testfield("Applies-to Doc. No.", '');
            if (SalesHeader."Applies-to ID" <> '') and (Rec."TCS Nature of Collection" <> xRec."TCS Nature of Collection") then
                SalesHeader.Testfield("Applies-to ID", '');
        end;
    end;

    procedure UpdateTaxAmount(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        CalculateTax: Codeunit "Calculate Tax";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("TCS Nature of Collection", '<>%1', '');
        if SalesLine.FindSet() then begin
            SalesHeader.Modify();
            repeat
                CalculateTax.CallTaxEngineOnSalesLine(SalesLine, SalesLine);
            until SalesLine.Next() = 0;
        end;
    end;

    procedure UpdateTaxAmountOnSalesLine(SalesLine: Record "Sales Line")
    var
        Saleline: Record "Sales Line";
        CalculateTax: Codeunit "Calculate Tax";
    begin
        Saleline.SetRange("Document No.", SalesLine."Document No.");
        Saleline.SetRange("Document Type", SalesLine."Document Type");
        if Saleline.FindSet() then
            repeat
                CalculateTax.CallTaxEngineOnSalesLine(Saleline, SalesLine);
            until Saleline.Next() = 0;
    end;
}
