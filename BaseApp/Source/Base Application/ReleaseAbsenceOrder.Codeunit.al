codeunit 17385 "Release Absence Order"
{
    TableNo = "Absence Header";

    trigger OnRun()
    var
        AbsenceLine: Record "Absence Line";
    begin
        if Status = Status::Released then
            exit;

        TestField("Employee No.");
        TestField("No.");
        TestField("Document Date");
        TestField("HR Order No.");
        TestField("HR Order Date");
        TestField("Posting Date");
        case "Document Type" of
            "Document Type"::"Sick Leave":
                // TESTFIELD("Sick Certificate Series");
                // TESTFIELD("Sick Certificate No.");
                // TESTFIELD("Sick Certificate Date");
                // TESTFIELD("Sick Certificate Reason");
                ;
            "Document Type"::Travel:
                begin
                    TestField("Travel Destination");
                    TestField("Travel Purpose");
                    if "Travel Paid By Type" > 0 then
                        TestField("Travel Paid by No.");
                    TestField("Travel Reason Document");
                end;
        end;

        AbsenceLine.Reset();
        AbsenceLine.SetRange("Document Type", "Document Type");
        AbsenceLine.SetRange("Document No.", "No.");
        if AbsenceLine.FindSet then
            repeat
                // NOT NEEDED ANYMORE?
                // IF EmplJobEntry.PositionChangeExist(
                // AbsenceLine."Employee No.",AbsenceLine."Start Date",AbsenceLine."End Date")
                // THEN
                // ERROR(Text004,AbsenceLine."Document Type",AbsenceLine."Start Date",AbsenceLine."End Date");

                AbsenceLine.TestField("Start Date");
                AbsenceLine.TestField("End Date");
                AbsenceLine.TestField("Time Activity Code");
                AbsenceLine.TestField("Element Code");
                case "Document Type" of
                    "Document Type"::Vacation:
                        begin
                            AbsenceLine.TestField("Vacation Type");
                            AbsenceLine.TestField("Calendar Days");
                            // AbsenceLine.TESTFIELD("Work Period Start Date");
                        end;
                    "Document Type"::"Sick Leave":
                        begin
                            AbsenceLine.TestField("Sick Leave Type");
                            if AbsenceLine."Sick Leave Type" in
                               [AbsenceLine."Sick Leave Type"::"Family Member Care",
                                AbsenceLine."Sick Leave Type"::"Child Care 1.5 years",
                                AbsenceLine."Sick Leave Type"::"Child Care 3 years"]
                            then
                                AbsenceLine.TestField("Relative Person No.");
                        end;
                    "Document Type"::Travel:
                        ;
                end;
            until AbsenceLine.Next() = 0
        else
            Error(Text001, "Document Type", "No.");

        Status := Status::Released;
        Modify(true);
    end;

    var
        Text001: Label 'There is nothing to release for %1 Order %2.';

    [Scope('OnPrem')]
    procedure Reopen(var AbsenceHeader: Record "Absence Header")
    begin
        with AbsenceHeader do begin
            if Status = Status::Open then
                exit;
            Status := Status::Open;
            Modify(true);
        end;
    end;
}

