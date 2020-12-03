/*
* Copyright (c) 2020 Elastos Foundation
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import Foundation
import PromiseKit

/// Credential is a set of one or more claims made by the same entity.
/// Credentials might also include an identifier and metadata to describe properties of the credential.
@objc(VerifiableCredential)
public class VerifiableCredential: DIDObject {
    private var _types: Array<String> = []
    private var _issuer: DID?
    private var _issuanceDate: Date?
    private var _expirationDate: Date?
    private var _subject: VerifiableCredentialSubject?
    private var _proof: VerifiableCredentialProof?
    private var _metadata: CredentialMeta?

    private let RULE_EXPIRE : Int = 1
    private let RULE_GENUINE: Int = 2
    private let RULE_VALID  : Int = 3

    override init() {
        super.init()
    }

    init(_ credential: VerifiableCredential) {
        super.init(credential.getId(), credential.getType())

        self._types = credential.getTypes()
        self._issuer = credential.issuer
        self._issuanceDate = credential.issuanceDate
        self._expirationDate = credential.expirationDate
        self._subject = credential.subject
        self._proof = credential.proof
    }

    override func setId(_ id: DIDURL) {
        super.setId(id)
    }

    /// Get string of Credential types.
    /// - Returns: String of Credential type.
    @objc
    public override func getType() -> String {
        var builder = ""
        var first = true

        builder.append("[")
        for type in _types {
            builder.append(!first ? ", ": "")
            builder.append(type)

            if  first {
                first = true
            }
        }
        builder.append("]")

        return builder
    }

    /// Get array of Credential types.
    /// - Returns: Array of Credential types.
    @objc
    public func getTypes() -> [String] {
        return self._types
    }

    func appendType(_ type: String) {
        self._types.append(type)
    }

    func setType(_ newTypes: [String]) {
        for type in newTypes {
            self._types.append(type)
        }
    }

    /// Get DID issuer of Credential.
    @objc
    public var issuer: DID {
        // Guaranteed that this field would not be nil because the object
        // was generated by "builder".
        return self._issuer!
    }

    // This type of getXXXX function would specifically be provided for
    // sdk internal when we can't be sure about it's validity/integrity.
    func getIssuer() -> DID? {
        return self._issuer
    }

    func setIssuer(_ newIssuer: DID) {
        self._issuer = newIssuer
    }

    /// Get date of issuing credential.
    @objc
    public var issuanceDate: Date {
        // Guaranteed that this field would not be nil because the object
        // was generated by "builder".
        return _issuanceDate!
    }

    func getIssuanceDate() -> Date? {
        return _issuanceDate
    }

    func setIssuanceDate(_ issuanceDate: Date) {
        self._issuanceDate = issuanceDate
    }

    /// Get the date of credential expired.
    @objc
    public var expirationDate: Date {
        // Guaranteed that this field would not be nil because the object
        // was generated by "builder".
        return _expirationDate!
    }

    func getExpirationDate() -> Date? {
        return _expirationDate
    }

    func setExpirationDate(_ expirationDate: Date) {
        self._expirationDate = expirationDate
    }

    func getMeta() -> CredentialMeta {
        if  self._metadata == nil {
            self._metadata = CredentialMeta()

            getId().setMetadata(_metadata!)
        }
        return self._metadata!
    }

    func setMetadata(_ newValue: CredentialMeta) {
        self._metadata = newValue
        getId().setMetadata(newValue)
    }

    /// Get credential alias.
    /// - Returns: CredentialMeta instance.
    @objc
    public func getMetadata() -> CredentialMeta {
        return getMeta()
    }

    /// Set Credential from DID Store.
    /// - Throws: if an error occurred, throw error.
    @objc
    public func saveMetadata() throws {
        if _metadata != nil && _metadata!.attachedStore {
            try _metadata?.store?.storeCredentialMetadata(subject.did, getId(), _metadata!)
        }
    }

    /// Credential is self proclaimed or not.
    /// - Returns: true if is self proclaimed, or  false.
    @objc
    public func isSelfProclaimed() -> Bool {
        return issuer == subject.did
    }
    
    private func traceCheck(_ rule: Int) throws -> Bool {
        var controllerDoc: DIDDocument?
        do {
            controllerDoc = try issuer.resolve()
        } catch {
            controllerDoc = nil
        }

        guard let _ = controllerDoc else {
            return false
        }

        switch rule {
        case RULE_EXPIRE:
            if controllerDoc!.isExpired {
                return true
            }
        case RULE_GENUINE:
            if !controllerDoc!.isGenuine {
                return false
            }
        case RULE_VALID:
            if !controllerDoc!.isValid {
                return false
            }
        default:
            break
        }

        if !isSelfProclaimed() {
            let issuerDoc: DIDDocument?
            do {
                issuerDoc = try issuer.resolve()
            } catch {
                issuerDoc = nil
            }
            guard let _ = issuerDoc else {
                return false
            }

            switch rule {
            case RULE_EXPIRE:
                if issuerDoc!.isExpired {
                    return true
                }
            case RULE_GENUINE:
                if !issuerDoc!.isGenuine {
                    return false
                }
            case RULE_VALID:
                if !issuerDoc!.isValid {
                    return false
                }
            default:
                break
            }
        }

        return rule != RULE_EXPIRE
    }
    
    private func checkExpired() throws -> Bool {
        return _expirationDate != nil ? DateHelper.isExipired(_expirationDate!) : false
    }

    /// Credential is expired or not.
    /// Issuance always occurs before any other actions involving a credential.
    @objc
    public var isExpired: Bool {
        do {
            return try traceCheck(RULE_EXPIRE) ? true : checkExpired()
        } catch {
            return false
        }
    }

    /// Credential is expired or not asynchronous.
    /// - Returns: Issuance always occurs before any other actions involving a credential.
    public func isExpiredAsync() -> Promise<Bool> {
        return Promise<Bool> { $0.fulfill(isExpired) }
    }

    /// Credential is expired or not asynchronous.
    /// - Returns: Issuance always occurs before any other actions involving a credential.
    @objc
    public func isExpiredAsyncUsingObjectC() -> AnyPromise {
        return AnyPromise(__resolverBlock: { [self] resolver in
            resolver(isExpired)
        })
    }

    private func checkGenuine() throws -> Bool {
        let doc = try issuer.resolve()

        guard let _ = doc else {
            return false
        }
        // Credential should signed by authentication key.
        guard doc!.containsAuthenticationKey(forId: proof.verificationMethod) else {
            return false
        }
        // Unsupported public key type;
        guard proof.type == Constants.DEFAULT_PUBLICKEY_TYPE else {
            return false
        }

        guard let data = toJson(true, true).data(using: .utf8) else {
            throw DIDError.illegalArgument("credential is nil")
        }
        return try doc!.verify(proof.verificationMethod, proof.signature, [data])
    }

    /// Credential is genuine or not.
    /// Issuance always occurs before any other actions involving a credential.
    /// flase if not genuine, true if genuine.
    @objc
    public var isGenuine: Bool {
        do {
            if try !traceCheck(RULE_GENUINE) {
                return false
            }
            return try checkGenuine()
        } catch {
            return false
        }
    }

    /// Credential is genuine or not asynchronous.
    /// Issuance always occurs before any other actions involving a credential.
    /// flase if not genuine, true if genuine.
    public func isGenuineAsync() -> Promise<Bool> {
        return Promise<Bool> { $0.fulfill(isGenuine) }
    }

    /// Credential is genuine or not asynchronous.
    /// Issuance always occurs before any other actions involving a credential.
    /// flase if not genuine, true if genuine.
    @objc
    public func isGenuineAsyncUsingObjectC() -> AnyPromise {
        return AnyPromise(__resolverBlock: { [self] resolver in
            resolver(isGenuine)
        })
    }

    /// Credential is expired or not.
    /// Issuance always occurs before any other actions involving a credential.
    @objc
    public var isValid: Bool {
        do {
            if try !traceCheck(RULE_VALID) {
                return false
            }
            return try !checkExpired() && checkGenuine()
        } catch {
            return false
        }
    }

    /// Credential is expired or not asynchronous.
    /// - Returns: flase if not genuine, true if genuine.
    public func isValidAsync() -> Promise<Bool> {
        return Promise<Bool> { $0.fulfill(isValid) }
    }

    /// Credential is expired or not asynchronous.
    /// - Returns: flase if not genuine, true if genuine.
    @objc
    public func isValidAsyncUsingObjectC() -> AnyPromise {
        return AnyPromise(__resolverBlock: { [self] resolver in
            resolver(isValid)
        })
    }
    /// claims about the subject of the credential
    @objc
    public var subject: VerifiableCredentialSubject {
        return _subject!
    }

    func getSubject() -> VerifiableCredentialSubject? {
        return _subject
    }

    func setSubject(_ newSubject: VerifiableCredentialSubject) {
        self._subject = newSubject
    }

    /// digital proof that makes the credential tamper-evident
    @objc
    public var proof: VerifiableCredentialProof {
        return _proof!
    }

    func getProof() -> VerifiableCredentialProof? {
        return _proof
    }

    func setProof(_ newProof: VerifiableCredentialProof) {
        self._proof = newProof
    }

    func checkIntegrity() -> Bool {
        return (!getTypes().isEmpty && _subject != nil)
    }

    func parse(_ node: JsonNode, _ ref: DID?) throws  {
        let error = { (des) -> DIDError in
            return DIDError.malformedCredential(des)
        }

        let serializer = JsonSerializer(node)
        var options: JsonSerializer.Options

        let arrayNode = node.get(forKey: Constants.TYPE)?.asArray()
        guard let _ = arrayNode else {
            throw DIDError.malformedCredential("missing credential type")
        }
        for item in arrayNode! {
            appendType(item.toString())
        }

        options = JsonSerializer.Options()
            .withHint("credential expirationDate")
            .withError(error)
        let expirationDate = try serializer.getDate(Constants.EXPIRATION_DATE, options)

        options = JsonSerializer.Options()
            .withRef(ref)
            .withHint("credential id")
            .withError(error)
        let id = try serializer.getDIDURL(Constants.ID, options)

        var subNode = node.get(forKey: Constants.CREDENTIAL_SUBJECT)
        guard let _ = subNode else {
            throw DIDError.malformedCredential("missing credential subject.")
        }
        let subject = try VerifiableCredentialSubject.fromJson(subNode!, ref)

        subNode = node.get(forKey: Constants.PROOF)
        guard let _ = subNode else {
            throw DIDError.malformedCredential("missing credential proof")
        }

        options = JsonSerializer.Options()
            .withOptional()
            .withHint("credential issuer")
            .withError(error)
        if ref != nil {
            options.withRef(ref)
        }
        var issuer = try? serializer.getDID(Constants.ISSUER, options)
        options = JsonSerializer.Options()
            .withHint("credential issuanceDate")
            .withError(error)
        let issuanceDate = try serializer.getDate(Constants.ISSUANCE_DATE, options)

        if issuer == nil {
            issuer = subject.did
        }
        let proof = try VerifiableCredentialProof.fromJson(subNode!, issuer)

        setIssuer(issuer!)
        setIssuanceDate(issuanceDate)
        setExpirationDate(expirationDate)
        setSubject(subject)
        setId(id!)
        setProof(proof)

        guard let _ = getIssuer() else {
            setIssuer(self.subject.did)
            return
        }
    }

    class func fromJson(_ node: JsonNode, _ ref: DID?) throws -> VerifiableCredential {
        let credential = VerifiableCredential()
        try credential.parse(node, ref)
        return credential
    }

    /// Get one DID’s Credential from json context.
    /// - Parameter json: Json context about credential.
    /// - Throws: If error occurs, throw error.
    /// - Returns: VerifiableCredential instance.
    @objc
    public class func fromJson(_ json: Data) throws -> VerifiableCredential {
        guard !json.isEmpty else {
            throw DIDError.illegalArgument()
        }

        let data: [String: Any]?
        do {
            data = try JSONSerialization.jsonObject(with: json, options: []) as? [String: Any]
        } catch {
            throw DIDError.didResolveError("Parse resolve result error")
        }
        guard let _  = data else {
            throw DIDError.didResolveError("Parse resolve result error")
        }
        return try fromJson(JsonNode(data!), nil)
    }

    /// Get one DID’s Credential from json context.
    /// - Parameter json: Json context about credential.
    /// - Throws: If error occurs, throw error.
    /// - Returns: VerifiableCredential instance.
    @objc(fromJsonWithJson:error:)
    public class func fromJson(_ json: String) throws -> VerifiableCredential {
        return try fromJson(json.data(using: .utf8)!)
    }

    /// Get one DID’s Credential from json context.
    /// - Parameter json: Json context about credential.
    /// - Throws: If error occurs, throw error.
    /// - Returns: VerifiableCredential instance.
    @objc(fromJsonWithDict:error:)
    public class func fromJson(_ json: [String: Any]) throws -> VerifiableCredential {
        return try fromJson(JsonNode(json), nil)
    }

    func toJson(_ generator: JsonGenerator, _ ref: DID?, _ normalized: Bool) {
        toJson(generator, ref, normalized, false)
    }

    func toJson(_ generator: JsonGenerator, _ normalized: Bool) {
        toJson(generator, nil, normalized)
    }

    /*
    * Normalized serialization order:
    *
    * - id
    * - type ordered names array(case insensitive/ascending)
    * - issuer
    * - issuanceDate
    * - expirationDate
    * + credentialSubject
    *   - id
    *   - properties ordered by name(case insensitive/ascending)
    * + proof
    *   - type
    *   - method
    *   - signature
    */
    func toJson(_ generator: JsonGenerator, _ ref: DID?, _ normalized: Bool, _ forSign: Bool) {
        generator.writeStartObject()

        // id
        generator.writeFieldName(Constants.ID)
        generator.writeString(IDGetter(getId(), ref).value(normalized))

        // type
        generator.writeFieldName(Constants.TYPE)
        _types.sort { (a, b) -> Bool in
            let compareResult = a.compare(b)
            return compareResult == ComparisonResult.orderedAscending
        }
        generator.writeStartArray()
        for type in getTypes() {
            generator.writeString(type)
        }
        generator.writeEndArray()

        // issuer
        if normalized || issuer != subject.did {
            generator.writeStringField(Constants.ISSUER, issuer.toString())
        }

        // issuanceDate
        generator.writeFieldName(Constants.ISSUANCE_DATE)
        generator.writeString(DateFormatter.convertToUTCStringFromDate(issuanceDate))

        // expirationDate
        if let _ = getExpirationDate() {
            generator.writeFieldName(Constants.EXPIRATION_DATE)
            generator.writeString(DateFormatter.convertToUTCStringFromDate(expirationDate))
        }

        // credenitalSubject
        generator.writeFieldName(Constants.CREDENTIAL_SUBJECT)
        subject.toJson(generator, ref, normalized)

        // proof
        if !forSign {
            generator.writeFieldName(Constants.PROOF)
            proof.toJson(generator, issuer, normalized)
        }

        generator.writeEndObject()
    }

    func toJson(_ normalized: Bool, _ forSign: Bool) -> String {
        let generator = JsonGenerator()
        toJson(generator, nil, normalized, forSign)
        return generator.toString()
    }
}

extension VerifiableCredential {
    @objc
    public func toString(_ normalized: Bool) -> String {
        return toJson(normalized, false)
    }

    func toString() -> String {
        return toString(false)
    }

    @objc
    public override var description: String {
        return toString()
    }
}
