import CLibpq
@_exported import SQL

public class Result: SQL.ResultProtocol {

    public enum Error: ErrorProtocol {
        case BadStatus(Status, String)
    }

    public enum Status: Int, ResultStatus {
        case EmptyQuery
        case CommandOK
        case TuplesOK
        case CopyOut
        case CopyIn
        case BadResponse
        case NonFatalError
        case FatalError
        case CopyBoth
        case SingleTuple
        case Unknown

        public init(status: ExecStatusType) {
            switch status {
            case PGRES_EMPTY_QUERY:
                self = .EmptyQuery
                break
            case PGRES_COMMAND_OK:
                self = .CommandOK
                break
            case PGRES_TUPLES_OK:
                self = .TuplesOK
                break
            case PGRES_COPY_OUT:
                self = .CopyOut
                break
            case PGRES_COPY_IN:
                self = .CopyIn
                break
            case PGRES_BAD_RESPONSE:
                self = .BadResponse
                break
            case PGRES_NONFATAL_ERROR:
                self = .NonFatalError
                break
            case PGRES_FATAL_ERROR:
                self = .FatalError
                break
            case PGRES_COPY_BOTH:
                self = .CopyBoth
                break
            case PGRES_SINGLE_TUPLE:
                self = .SingleTuple
                break
            default:
                self = .Unknown
                break
            }
        }

        public var successful: Bool {
            return self != .BadResponse && self != .FatalError
        }
    }

    internal init(_ resultPointer: OpaquePointer) throws {
        self.resultPointer = resultPointer

        guard status.successful else {
            throw Error.BadStatus(status, String(validatingUTF8: PQresultErrorMessage(resultPointer)) ?? "No error message")
        }
    }

    deinit {
        clear()
    }

    public subscript(position: Int) -> Row {
        return Row(result: self, index: position)
    }

    public func data(atRow rowIndex: Int, forFieldIndex fieldIndex: Int) -> Data? {

        let start = PQgetvalue(resultPointer, Int32(rowIndex), Int32(fieldIndex))
        let count = PQgetlength(resultPointer, Int32(rowIndex), Int32(fieldIndex))

        let buffer = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(start), count: Int(count))

        return Data(Array(buffer))
    }

    public var count: Int {
        return Int(PQntuples(self.resultPointer))
    }

    lazy public var countAffected: Int = {
        guard let str = String(validatingUTF8: PQcmdTuples(self.resultPointer)) else {
            return 0
        }

        return Int(str) ?? 0
    }()

    public var status: Status {
        return Status(status: PQresultStatus(resultPointer))
    }

    private let resultPointer: OpaquePointer

    public func clear() {
        PQclear(resultPointer)
    }

    public lazy var fieldsByName: [String: FieldInfo] = {
        var result = [String:FieldInfo]()

        for i in 0..<PQnfields(self.resultPointer) {
            guard let fieldName = String(validatingUTF8: PQfname(self.resultPointer, i)) else {
                continue
            }

            result[fieldName] = FieldInfo(name: fieldName, index: Int(i))
        }

        return result

    }()
}
