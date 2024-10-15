codeunit 12415 "EmployeeVendor-Update"
{

    trigger OnRun()
    begin
    end;

    var
        Vend: Record Vendor;
        Text001: Label '%1 No %2 already exists.';

    [Scope('OnPrem')]
    procedure OnInsert(var Employee: Record Employee)
    begin
        with Vend do begin
            if Get(Employee."No.") then
                Error(Text001, Format("Vendor Type"), Employee."No.");

            Init;
            "No." := Employee."No.";
            "Vendor Type" := "Vendor Type"::"Resp. Employee";
            EmployeeToVendor(Employee, Vend);
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure OnModify(var Employee: Record Employee)
    begin
        Vend.SetRange("Employee No.", Employee."No.");
        if Vend.FindSet then
            repeat
                Vend.TestField("Vendor Type", Vend."Vendor Type"::"Resp. Employee");
                EmployeeToVendor(Employee, Vend);
                Vend.Modify(true);
            until Vend.Next = 0;
    end;

    local procedure EmployeeToVendor(var Employee: Record Employee; var Vendor: Record Vendor)
    var
        PurchaseSetup: Record "Purchases & Payables Setup";
    begin
        with Vendor do begin
            Validate(Name, Employee."Short Name");
            "Country/Region Code" := Employee."Country/Region Code";
            Address := Employee.Address;
            "Address 2" := Employee."Address 2";
            City := Employee.City;
            "Phone No." := Employee."Phone No.";
            "Fax No." := Employee."Fax No.";
            "Post Code" := Employee."Post Code";
            "E-Mail" := Employee."E-Mail";
            "Employee No." := Employee."No.";
            PurchaseSetup.Get();
            "Gen. Bus. Posting Group" := PurchaseSetup."Adv. Stmt. Gen.Bus. Posting Gr";
            "VAT Bus. Posting Group" := PurchaseSetup."Adv. Stmt. VAT Bus. Posting Gr";
            "Vendor Posting Group" := PurchaseSetup."Adv. Stmt. Vendor Posting Gr.";
        end;
    end;

    [Scope('OnPrem')]
    procedure OnRename(OldEmployeeNo: Code[20]; NewEmployeeNo: Code[20])
    begin
        if Vend.Get(OldEmployeeNo) then begin
            Vend.TestField("Vendor Type", Vend."Vendor Type"::"Resp. Employee");
            Vend.Rename(NewEmployeeNo);
        end;
    end;
}

