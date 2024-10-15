codeunit 17350 "Record of Service Management"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure CalcPersonTotalService(PersonNo: Code[20]; UnbrokenService: Boolean; var ServicePeriod: array[3] of Integer)
    var
        RecordOfService: Record "Person Job History";
        TotalDays: Integer;
    begin
        // Function calculate total seniority based on personal job history
        with RecordOfService do begin
            Reset;
            SetRange("Person No.", PersonNo);
            if UnbrokenService then
                SetRange("Unbroken Record of Service", true);
            if FindSet then
                repeat
                    TestField("Ending Date");
                    TotalDays += "Ending Date" - "Starting Date";
                    if "Insured Period Starting Date" <> 0D then
                        TotalDays := TotalDays + 1;
                until Next() = 0;

            CalcServicePeriod(TotalDays, ServicePeriod);
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcPersonInsuredService(PersonNo: Code[20]; var ServicePeriod: array[3] of Integer)
    var
        RecordOfService: Record "Person Job History";
        PrevStartDate: Date;
        PrevEndDate: Date;
    begin
        // Function calculates insurance seniority based on personal job history
        with RecordOfService do begin
            Reset;
            SetRange("Person No.", PersonNo);
            if FindSet then
                repeat
                    if "Insured Period Starting Date" <> 0D then begin
                        TestField("Insured Period Ending Date");
                        ProcessISEntry(
                          "Insured Period Starting Date", "Insured Period Ending Date",
                          PrevStartDate, PrevEndDate, ServicePeriod);
                    end;
                until Next() = 0;

            if PrevStartDate <> 0D then
                AddToServicePeriod(PrevStartDate, PrevEndDate, ServicePeriod);
            NormalizeServicePeriod(ServicePeriod);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdatePersonService(PersonNo: Code[20]; TotalService: array[3] of Integer; InsuredService: array[3] of Integer; UnbrokenService: array[3] of Integer)
    var
        Person: Record Person;
    begin
        Person.Get(PersonNo);
        with Person do
            if (("Total Service (Days)" <> TotalService[1]) or
                ("Total Service (Months)" <> TotalService[2]) or
                ("Total Service (Years)" <> TotalService[3]) or
                ("Insured Service (Days)" <> InsuredService[1]) or
                ("Insured Service (Months)" <> InsuredService[2]) or
                ("Insured Service (Years)" <> InsuredService[3]) or
                ("Unbroken Service (Days)" <> UnbrokenService[1]) or
                ("Unbroken Service (Months)" <> UnbrokenService[2]) or
                ("Unbroken Service (Years)" <> UnbrokenService[3]))
            then begin
                "Total Service (Days)" := TotalService[1];
                "Total Service (Months)" := TotalService[2];
                "Total Service (Years)" := TotalService[3];
                "Insured Service (Days)" := InsuredService[1];
                "Insured Service (Months)" := InsuredService[2];
                "Insured Service (Years)" := InsuredService[3];
                "Unbroken Service (Days)" := UnbrokenService[1];
                "Unbroken Service (Months)" := UnbrokenService[2];
                "Unbroken Service (Years)" := UnbrokenService[3];
                Modify;
            end;
    end;

    [Scope('OnPrem')]
    procedure CalcEmplTotalService(Employee: Record Employee; CurrentDate: Date; UnbrokenService: Boolean; var ServicePeriod: array[3] of Integer)
    var
        Person: Record Person;
        EmplJobEntry: Record "Employee Job Entry";
        PrevStartDate: Date;
        PrevEndDate: Date;
    begin
        // Function calculate total seniority based on job history and current date
        Clear(ServicePeriod);
        if Person.Get(Employee."Person No.") then
            if UnbrokenService then begin
                ServicePeriod[1] := Person."Unbroken Service (Days)";
                ServicePeriod[2] := Person."Unbroken Service (Months)";
                ServicePeriod[3] := Person."Unbroken Service (Years)";
            end else begin
                ServicePeriod[1] := Person."Total Service (Days)";
                ServicePeriod[2] := Person."Total Service (Months)";
                ServicePeriod[3] := Person."Total Service (Years)";
            end;

        with EmplJobEntry do begin
            Reset;
            SetRange("Employee No.", Employee."No.");
            if UnbrokenService then
                SetRange("Uninterrupted Service", true);
            if FindSet then
                repeat
                    if ("Ending Date" = 0D) or (CurrentDate < "Ending Date") then
                        "Ending Date" := CurrentDate;

                    if "Starting Date" <> 0D then
                        ProcessISEntry(
                          "Starting Date", "Ending Date", PrevStartDate, PrevEndDate, ServicePeriod);
                until Next() = 0;

            if PrevStartDate <> 0D then
                AddToServicePeriod(PrevStartDate, PrevEndDate, ServicePeriod);
            NormalizeServicePeriod(ServicePeriod);

        end;
    end;

    [Scope('OnPrem')]
    procedure CalcEmplInsuredService(Employee: Record Employee; CurrentDate: Date; var ServicePeriod: array[3] of Integer)
    var
        Person: Record Person;
        EmplJobEntry: Record "Employee Job Entry";
        PrevStartDate: Date;
        PrevEndDate: Date;
    begin
        // Function calculates insurance seniority based on job history and current date
        Clear(ServicePeriod);
        if Person.Get(Employee."Person No.") then begin
            ServicePeriod[1] := Person."Insured Service (Days)";
            ServicePeriod[2] := Person."Insured Service (Months)";
            ServicePeriod[3] := Person."Insured Service (Years)";
        end;

        with EmplJobEntry do begin
            Reset;
            SetRange("Employee No.", Employee."No.");
            if FindSet then
                repeat
                    if "Insured Period Starting Date" <> 0D then
                        if ("Insured Period Ending Date" = 0D) or (CurrentDate < "Insured Period Ending Date") then
                            "Insured Period Ending Date" := CurrentDate;
                    if "Insured Period Starting Date" <> 0D then
                        ProcessISEntry(
                          "Insured Period Starting Date", "Insured Period Ending Date",
                          PrevStartDate, PrevEndDate, ServicePeriod);
                until Next() = 0;

            if PrevStartDate <> 0D then
                AddToServicePeriod(PrevStartDate, PrevEndDate, ServicePeriod);
            NormalizeServicePeriod(ServicePeriod);
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcServicePeriod(TotalDays: Integer; var ServicePeriod: array[3] of Integer)
    begin
        ServicePeriod[1] := TotalDays mod 30;
        ServicePeriod[2] := TotalDays div 30;
        ServicePeriod[3] := ServicePeriod[2] div 12;
        ServicePeriod[2] := ServicePeriod[2] mod 12;
    end;

    local procedure AddToServicePeriod(StartDate: Date; EndDate: Date; var ServicePeriod: array[3] of Integer)
    var
        DifferenceMonths: Integer;
    begin
        if (Date2DMY(StartDate, 1) = 1) and (EndDate = CalcDate('<+CM>', StartDate)) then begin
            ServicePeriod[2] += 1;
            exit;
        end;
        if (Date2DMY(StartDate, 1) <> 1) or (EndDate < CalcDate('<+CM>', StartDate)) then
            ServicePeriod[1] += (CalcDate('<+CM>', StartDate) - StartDate) + 1
        else
            ServicePeriod[2] += 1;
        if (CalcDate('<+CM>', EndDate) <> EndDate) or (StartDate > CalcDate('<-CM>', EndDate)) then
            ServicePeriod[1] += (EndDate - CalcDate('<-CM>', EndDate)) + 1
        else
            ServicePeriod[2] += 1;
        StartDate := CalcDate('<+CM+1D>', StartDate);
        EndDate := CalcDate('<-CM>', EndDate);
        if (StartDate > EndDate) then
            ServicePeriod[1] -= (StartDate - EndDate)
        else begin
            ServicePeriod[3] += Date2DMY(EndDate, 3) - Date2DMY(StartDate, 3);
            DifferenceMonths := Date2DMY(EndDate, 2) - Date2DMY(StartDate, 2);
            if DifferenceMonths < 0 then begin
                ServicePeriod[3] -= 1;
                DifferenceMonths += 12;
            end;
            ServicePeriod[2] += DifferenceMonths;
        end;
    end;

    local procedure NormalizeServicePeriod(var ServicePeriod: array[3] of Integer)
    var
        TotalMonths: Integer;
    begin
        TotalMonths := ServicePeriod[1] div 30;
        ServicePeriod[1] := ServicePeriod[1] mod 30;
        ServicePeriod[2] += TotalMonths;
        ServicePeriod[3] += ServicePeriod[2] div 12;
        ServicePeriod[2] := ServicePeriod[2] mod 12;
    end;

    local procedure ProcessISEntry(IPStartDate: Date; IPEndDate: Date; var PrevStartDate: Date; var PrevEndDate: Date; var ServicePeriod: array[3] of Integer)
    begin
        if PrevStartDate <> 0D then begin
            if (IPStartDate - PrevEndDate) <> 1 then begin
                AddToServicePeriod(PrevStartDate, PrevEndDate, ServicePeriod);
                PrevStartDate := IPStartDate;
            end
        end else
            PrevStartDate := IPStartDate;
        PrevEndDate := IPEndDate;
        if PrevStartDate > PrevEndDate then
            PrevStartDate := PrevEndDate + 1;
    end;
}

