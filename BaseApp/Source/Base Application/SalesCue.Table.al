table 9053 "Sales Cue"
{
    Caption = 'Sales Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Sales Quotes - Open"; Integer)
        {
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = FILTER(Quote),
                                                      Status = FILTER(Open),
                                                      "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Sales Quotes - Open';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Sales Orders - Open"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = FILTER(Order),
                                                      Status = FILTER(Open),
                                                      "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Sales Orders - Open';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Ready to Ship"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = FILTER(Order),
                                                      Status = FILTER(Released),
                                                      "Completely Shipped" = CONST(false),
                                                      "Shipment Date" = FIELD("Date Filter2"),
                                                      "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Ready to Ship';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; Delayed; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = FILTER(Order),
                                                      Status = FILTER(Released),
                                                      "Completely Shipped" = CONST(false),
                                                      "Shipment Date" = FIELD("Date Filter"),
                                                      "Responsibility Center" = FIELD("Responsibility Center Filter"),
                                                      "Late Order Shipping" = FILTER(true)));
            Caption = 'Delayed';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Sales Return Orders - Open"; Integer)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = FILTER("Return Order"),
                                                      Status = FILTER(Open),
                                                      "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Sales Return Orders - Open';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Sales Credit Memos - Open"; Integer)
        {
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = FILTER("Credit Memo"),
                                                      Status = FILTER(Open),
                                                      "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Sales Credit Memos - Open';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Partially Shipped"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = FILTER(Order),
                                                      Status = FILTER(Released),
                                                      Shipped = FILTER(true),
                                                      "Completely Shipped" = FILTER(false),
                                                      "Shipment Date" = FIELD("Date Filter2"),
                                                      "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Partially Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Average Days Delayed"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Average Days Delayed';
            DecimalPlaces = 1 : 1;
            Editable = false;
        }
        field(10; "Sales Inv. - Pending Doc.Exch."; Integer)
        {
            CalcFormula = Count ("Sales Invoice Header" WHERE("Document Exchange Status" = FILTER("Sent to Document Exchange Service" | "Delivery Failed")));
            Caption = 'Sales Invoices - Pending Document Exchange';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Sales CrM. - Pending Doc.Exch."; Integer)
        {
            CalcFormula = Count ("Sales Cr.Memo Header" WHERE("Document Exchange Status" = FILTER("Sent to Document Exchange Service" | "Delivery Failed")));
            Caption = 'Sales Credit Memos - Pending Document Exchange';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(21; "Date Filter2"; Date)
        {
            Caption = 'Date Filter 2';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(22; "Responsibility Center Filter"; Code[10])
        {
            Caption = 'Responsibility Center Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(23; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetRespCenterFilter()
    var
        UserSetupMgt: Codeunit "User Setup Management";
        RespCenterCode: Code[10];
    begin
        RespCenterCode := UserSetupMgt.GetSalesFilter;
        if RespCenterCode <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center Filter", RespCenterCode);
            FilterGroup(0);
        end;
    end;

    procedure CalculateAverageDaysDelayed() AverageDays: Decimal
    var
        SalesHeader: Record "Sales Header";
        SumDelayDays: Integer;
        CountDelayedInvoices: Integer;
    begin
        FilterOrders(SalesHeader, FieldNo(Delayed));
        if SalesHeader.FindSet then begin
            repeat
                SumDelayDays += MaximumDelayAmongLines(SalesHeader);
                CountDelayedInvoices += 1;
            until SalesHeader.Next = 0;
            AverageDays := SumDelayDays / CountDelayedInvoices;
        end;
    end;

    local procedure MaximumDelayAmongLines(SalesHeader: Record "Sales Header") MaxDelay: Integer
    var
        SalesLine: Record "Sales Line";
    begin
        MaxDelay := 0;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Shipment Date", '<%1&<>%2', WorkDate, 0D);
        if SalesLine.FindSet then
            repeat
                if WorkDate - SalesLine."Shipment Date" > MaxDelay then
                    MaxDelay := WorkDate - SalesLine."Shipment Date";
            until SalesLine.Next = 0;
    end;

    procedure CountOrders(FieldNumber: Integer): Integer
    var
        SalesHeader: Record "Sales Header";
        CountSalesOrders: Query "Count Sales Orders";
    begin
        CountSalesOrders.SetRange(Status, SalesHeader.Status::Released);
        CountSalesOrders.SetRange(Completely_Shipped, false);
        FilterGroup(2);
        CountSalesOrders.SetFilter(Responsibility_Center, GetFilter("Responsibility Center Filter"));
        FilterGroup(0);

        case FieldNumber of
            FieldNo("Ready to Ship"):
                begin
                    CountSalesOrders.SetRange(Ship);
                    CountSalesOrders.SetFilter(Shipment_Date, GetFilter("Date Filter2"));
                end;
            FieldNo("Partially Shipped"):
                begin
                    CountSalesOrders.SetRange(Shipped, true);
                    CountSalesOrders.SetFilter(Shipment_Date, GetFilter("Date Filter2"));
                end;
            FieldNo(Delayed):
                begin
                    CountSalesOrders.SetRange(Ship);
                    CountSalesOrders.SetFilter(Date_Filter, GetFilter("Date Filter"));
                    CountSalesOrders.SetRange(Late_Order_Shipping, true);
                end;
        end;
        CountSalesOrders.Open;
        CountSalesOrders.Read;
        exit(CountSalesOrders.Count_Orders);
    end;

    local procedure FilterOrders(var SalesHeader: Record "Sales Header"; FieldNumber: Integer)
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.SetRange("Completely Shipped", false);
        case FieldNumber of
            FieldNo("Ready to Ship"):
                begin
                    SalesHeader.SetRange(Ship);
                    SalesHeader.SetFilter("Shipment Date", GetFilter("Date Filter2"));
                end;
            FieldNo("Partially Shipped"):
                begin
                    SalesHeader.SetRange(Shipped, true);
                    SalesHeader.SetFilter("Shipment Date", GetFilter("Date Filter2"));
                end;
            FieldNo(Delayed):
                begin
                    SalesHeader.SetRange(Ship);
                    SalesHeader.SetFilter("Date Filter", GetFilter("Date Filter"));
                    SalesHeader.SetRange("Late Order Shipping", true);
                end;
        end;
        FilterGroup(2);
        SalesHeader.SetFilter("Responsibility Center", GetFilter("Responsibility Center Filter"));
        FilterGroup(0);
    end;

    procedure ShowOrders(FieldNumber: Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        FilterOrders(SalesHeader, FieldNumber);
        PAGE.Run(PAGE::"Sales Order List", SalesHeader);
    end;
}

