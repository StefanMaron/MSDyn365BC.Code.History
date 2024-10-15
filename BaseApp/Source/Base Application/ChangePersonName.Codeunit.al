codeunit 17353 "Change Person Name"
{
    Permissions = TableData "Person Name History" = rid;

    trigger OnRun()
    begin
    end;

    var
        PersonNameHistory: Record "Person Name History";
        LaborContractLine: Record "Labor Contract Line";
        Text001: Label 'Approved hire contract is not found for person %1.';
        Text002: Label 'Start date %1 must be greater than hire contract starting date %2.';
        Text003: Label 'Start date %1 must be greater then last change name date %2.';
        Text004: Label 'Before you can cancel this change, you must first cancel all changes that were made after it.';
        Text005: Label 'Person name %1 will be changed to\%2. Continue?';

    [Scope('OnPrem')]
    procedure ChangeName(PersonNo: Code[20]; NewFirstName: Text[30]; NewMiddleName: Text[30]; NewLastName: Text[30]; OrderNo: Code[20]; OrderDate: Date; StartDate: Date; Description: Text[50])
    var
        Person: Record Person;
    begin
        PersonNameHistory.SetRange("Person No.", PersonNo);
        if not PersonNameHistory.FindLast then begin
            Person.Get(PersonNo);
            LaborContractLine.SetRange("Person No.", PersonNo);
            LaborContractLine.SetRange(Status, LaborContractLine.Status::Approved);
            if not LaborContractLine.FindFirst then
                Error(Text001, PersonNo);

            if StartDate <= LaborContractLine."Starting Date" then
                Error(Text002, StartDate, LaborContractLine."Starting Date");

            PersonNameHistory."Person No." := PersonNo;
            PersonNameHistory."Start Date" := LaborContractLine."Starting Date";
            PersonNameHistory."First Name" := Person."First Name";
            PersonNameHistory."Middle Name" := Person."Middle Name";
            PersonNameHistory."Last Name" := Person."Last Name";
            PersonNameHistory."Order No." := LaborContractLine."Order No.";
            PersonNameHistory."Order Date" := LaborContractLine."Order Date";
            PersonNameHistory."User ID" := UserId;
            PersonNameHistory."Creation Date" := Today;
            PersonNameHistory.Insert();
        end else
            if StartDate <= PersonNameHistory."Start Date" then
                Error(Text003, StartDate, PersonNameHistory."Start Date");

        PersonNameHistory.Init();
        PersonNameHistory."Person No." := PersonNo;
        PersonNameHistory."Start Date" := StartDate;
        PersonNameHistory."First Name" := NewFirstName;
        PersonNameHistory."Middle Name" := NewMiddleName;
        PersonNameHistory."Last Name" := NewLastName;
        PersonNameHistory."Order No." := OrderNo;
        PersonNameHistory."Order Date" := OrderDate;
        PersonNameHistory.Description := Description;
        PersonNameHistory."User ID" := UserId;
        PersonNameHistory."Creation Date" := Today;
        PersonNameHistory.Insert();

        UpdatePersonName(
          PersonNo,
          NewFirstName,
          NewMiddleName,
          NewLastName,
          StartDate);
    end;

    local procedure UpdatePersonName(PersonNo: Code[20]; NewFirstName: Text[30]; NewMiddleName: Text[30]; NewLastName: Text[30]; StartDate: Date)
    var
        Employee: Record Employee;
        Person: Record Person;
    begin
        with Person do begin
            Get(PersonNo);
            "First Name" := NewFirstName;
            "Middle Name" := NewMiddleName;
            "Last Name" := NewLastName;
            Initials := CopyStr("First Name", 1, 1) + '.' + CopyStr("Middle Name", 1, 1) + '.';
            "Last Name Change Date" := StartDate;
            Validate("Full Name", GetFullName);
            Modify;

            Employee.Reset();
            Employee.SetCurrentKey("Person No.");
            Employee.SetRange("Person No.", PersonNo);
            Employee.SetRange("Employment Date", 0D, StartDate);
            Employee.SetFilter("Termination Date", '%1|%2..', 0D, StartDate);
            if Employee.FindSet(true) then
                repeat
                    Employee.Validate("First Name", "First Name");
                    Employee.Validate("Middle Name", "Middle Name");
                    Employee.Validate("Last Name", "Last Name");
                    Employee.Modify();
                until Employee.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CancelChanges(var PersonNameHistoryToCancel: Record "Person Name History")
    var
        PrevPersonName: Record "Person Name History";
    begin
        PersonNameHistory.Copy(PersonNameHistoryToCancel);

        PersonNameHistory.FindLast;
        if PersonNameHistory."Start Date" <> PersonNameHistoryToCancel."Start Date" then
            Error(Text004);

        PrevPersonName.Copy(PersonNameHistoryToCancel);
        PrevPersonName.Next(-1);

        if not Confirm(
             Text005,
             true,
             PersonNameHistoryToCancel.GetFullName,
             PrevPersonName.GetFullName)
        then
            exit;

        UpdatePersonName(
          PrevPersonName."Person No.",
          PrevPersonName."First Name",
          PrevPersonName."Middle Name",
          PrevPersonName."Last Name",
          Today);

        if PersonNameHistory.Count <> 2 then
            PersonNameHistory.SetRecFilter;

        if PersonNameHistory.FindFirst then
            repeat
                PersonNameHistory.Delete();
            until PersonNameHistory.Next() = 0;
    end;
}

