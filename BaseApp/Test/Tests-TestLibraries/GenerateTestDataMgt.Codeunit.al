codeunit 130150 "Generate Test Data Mgt."
{
    TableNo = "Generate Test Data Line";

    trigger OnRun()
    var
        ChangeGlobalDimLogMgt: Codeunit "Change Global Dim. Log Mgt.";
    begin
        BindSubscription(ChangeGlobalDimLogMgt);
        RunTask(Rec);
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";

    procedure GetLines()
    var
        GenerateTestDataLine: Record "Generate Test Data Line";
    begin
        GenerateTestDataLine.Reset();
        GenerateTestDataLine.SetFilter(Status, '<>%1', GenerateTestDataLine.Status::"In Progress");
        GenerateTestDataLine.DeleteAll();

        AddTable(GenerateTestDataLine, DATABASE::Customer, 0);
        AddTable(GenerateTestDataLine, DATABASE::"Cust. Ledger Entry", 0);
        AddTable(GenerateTestDataLine, DATABASE::"Sales Header", 0);
        AddTable(GenerateTestDataLine, DATABASE::"Sales Line", DATABASE::"Sales Header");
        AddTable(GenerateTestDataLine, DATABASE::"Sales Invoice Header", 0);
        AddTable(GenerateTestDataLine, DATABASE::"Sales Invoice Line", DATABASE::"Sales Invoice Header");
        AddTable(GenerateTestDataLine, DATABASE::"Sales Cr.Memo Header", 0);
        AddTable(GenerateTestDataLine, DATABASE::"Sales Cr.Memo Line", DATABASE::"Sales Cr.Memo Header");
        AddTable(GenerateTestDataLine, DATABASE::Vendor, 0);
        AddTable(GenerateTestDataLine, DATABASE::"Vendor Ledger Entry", 0);
        AddTable(GenerateTestDataLine, DATABASE::"Purchase Header", 0);
        AddTable(GenerateTestDataLine, DATABASE::"Purchase Line", DATABASE::"Purchase Header");
        AddTable(GenerateTestDataLine, DATABASE::"Purch. Inv. Header", 0);
        AddTable(GenerateTestDataLine, DATABASE::"Purch. Inv. Line", DATABASE::"Purch. Inv. Header");
        AddTable(GenerateTestDataLine, DATABASE::"Purch. Cr. Memo Hdr.", 0);
        AddTable(GenerateTestDataLine, DATABASE::"Purch. Cr. Memo Line", DATABASE::"Purch. Cr. Memo Hdr.");
    end;

    local procedure AddTable(var GenerateTestDataLine: Record "Generate Test Data Line"; TableID: Integer; ParentTableID: Integer)
    begin
        with GenerateTestDataLine do
            if not Get(TableID) then begin
                Init();
                "Table ID" := TableID;
                "Parent Table ID" := ParentTableID;
                Enabled := IsEnabled("Table ID");
                Insert(true);
            end;
    end;

    local procedure CountRecords(TableID: Integer) TotalRecords: Integer
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        TotalRecords := RecRef.Count();
        RecRef.Close();
    end;

    local procedure IsEnabled(TableID: Integer): Boolean
    begin
        exit(
          TableID in
          [DATABASE::Customer, DATABASE::"Sales Header", DATABASE::"Sales Invoice Header", DATABASE::"Sales Cr.Memo Header",
           DATABASE::Vendor, DATABASE::"Purchase Header", DATABASE::"Purch. Inv. Header", DATABASE::"Purch. Cr. Memo Hdr."]);
    end;

    local procedure RunTask(var GenerateTestDataLine: Record "Generate Test Data Line")
    begin
        with GenerateTestDataLine do begin
            Get("Table ID");
            Status := Status::"In Progress";
            "Last Error Message" := '';
            "Session ID" := SessionId;
            "Service Instance ID" := ServiceInstanceId;
            Validate("Added Records", 0);
            Modify();
            Commit();

            GenerateData(GenerateTestDataLine);
        end;
    end;

    local procedure GenerateData(var GenerateTestDataLine: Record "Generate Test Data Line")
    var
        CurrentRecNo: Integer;
        RecNoToModify: Integer;
    begin
        with GenerateTestDataLine do begin
            RecNoToModify := Round("Records To Add" / 100, 1, '>');
            for CurrentRecNo := 1 to "Records To Add" do begin
                GenerateRecord(GenerateTestDataLine);
                if CurrentRecNo >= ("Added Records" + RecNoToModify) then begin
                    Validate("Added Records", CurrentRecNo);
                    Modify();
                    Commit();
                end;
            end;
            Validate("Added Records", "Records To Add");
            UpdateStatus();
            "Total Records" := CountRecords("Table ID");
            if Status = Status::Completed then begin
                Clear("Task ID");
                "Session ID" := 0;
                "Service Instance ID" := 0;
                "Records To Add" := 0;
                Validate("Added Records", 0);
                Status := Status::" ";
            end;
            Modify();
        end;
    end;

    local procedure GenerateRecord(var GenerateTestDataLine: Record "Generate Test Data Line")
    begin
        case GenerateTestDataLine."Table ID" of
            DATABASE::Customer:
                GenerateCustomer;
            DATABASE::"Sales Header":
                GenerateSalesDocument("Sales Document Type"::Order);
            DATABASE::"Sales Invoice Header":
                GeneratePostedSalesDocument("Sales Document Type"::Invoice);
            DATABASE::"Sales Cr.Memo Header":
                GeneratePostedSalesDocument("Sales Document Type"::"Credit Memo");
            DATABASE::Vendor:
                GenerateVendor;
            DATABASE::"Purchase Header":
                GeneratePurchDocument("Purchase Document Type"::Order);
            DATABASE::"Purch. Inv. Header":
                GeneratePostedPurchDocument("Purchase Document Type"::Invoice);
            DATABASE::"Purch. Cr. Memo Hdr.":
                GeneratePostedPurchDocument("Purchase Document Type"::"Credit Memo");
        end;
    end;

    local procedure GenerateCustomer() CustomerNo: Code[20]
    var
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        // with global dims
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
    end;

    local procedure GenerateSalesDocument(DocumentType: Enum "Sales Document Type") DocumentNo: Code[20]
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, GenerateCustomer);
        DocumentNo := SalesHeader."No.";
        for i := 1 to LibraryRandom.RandIntInRange(1, 10) do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
              LibraryERM.FindGLAccount(GLAccount), LibraryRandom.RandInt(100));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
            SalesLine.Modify(true);
        end;
    end;

    local procedure GeneratePostedSalesDocument(DocumentType: Enum "Sales Document Type") DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, GenerateSalesDocument(DocumentType));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure GenerateVendor() VendorNo: Code[20]
    var
        Vendor: Record Vendor;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        VendorNo := Vendor."No.";
        // with global dims
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, Vendor."No.", DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, Vendor."No.", DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
    end;

    local procedure GeneratePurchDocument(DocumentType: Enum "Purchase Document Type") DocumentNo: Code[20]
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, GenerateVendor);
        DocumentNo := PurchaseHeader."No.";
        for i := 1 to LibraryRandom.RandIntInRange(1, 10) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
              LibraryERM.FindGLAccount(GLAccount), LibraryRandom.RandInt(100));
            PurchaseLine.Validate("Unit Cost", LibraryRandom.RandDec(1000, 2));
            PurchaseLine.Modify(true);
        end;
    end;

    local procedure GeneratePostedPurchDocument(DocumentType: Enum "Purchase Document Type") DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, GeneratePurchDocument(DocumentType));
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    procedure ScheduleJobs(var GenerateTestDataLine: Record "Generate Test Data Line"; RecordsToAdd: Integer)
    var
        StartTime: DateTime;
    begin
        with GenerateTestDataLine do begin
            SetFilter(Status, '<>%1&<>%2', Status::Scheduled, Status::"In Progress");
            SetRange(Enabled, true);
            if not IsEmpty() then begin
                ModifyAll("Records To Add", RecordsToAdd);
                ModifyAll("Added Records", 0);
                ModifyAll("Session ID", 0);
                ModifyAll("Service Instance ID", 0);
                StartTime := CurrentDateTime;
                FindSet(true);
                repeat
                    StartTime += 100;
                    ScheduleJobForTable(StartTime);
                until Next = 0;
            end;
        end;
    end;
}

