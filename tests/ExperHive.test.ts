
import { describe, expect, it } from "vitest";
import {
  Cl,
  ClarityType,
  cvToValue,
  type ClarityValue,
  type ResponseOkCV,
} from "@stacks/transactions";

const contractName = "ExperHive";
const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const userA = accounts.get("wallet_1")!;
const userB = accounts.get("wallet_2")!;
const userC = accounts.get("wallet_3")!;

const callPublic = (method: string, args: ClarityValue[], sender: string) =>
  simnet.callPublicFn(contractName, method, args, sender).result;

const callReadOnly = (method: string, args: ClarityValue[], sender = deployer) =>
  simnet.callReadOnlyFn(contractName, method, args, sender).result;

const unwrapOk = (result: ClarityValue) => {
  expect(result).toHaveClarityType(ClarityType.ResponseOk);
  return (result as ResponseOkCV).value;
};

const cvToBigInt = (value: ClarityValue) => cvToValue(value) as bigint;

describe("ExperHive security controls", () => {
  it("pauses and resumes guarded flows", () => {
    let result = callPublic("emergency-pause", [], deployer);
    expect(result).toBeOk(Cl.stringAscii("Contract paused"));

    let paused = callReadOnly("is-contract-paused", []);
    expect(paused).toBeBool(true);

    result = callPublic("add-skill", [Cl.stringAscii("paused-skill")], userA);
    expect(result).toBeErr(Cl.uint(503));

    result = callPublic("emergency-unpause", [], deployer);
    expect(result).toBeOk(Cl.stringAscii("Contract unpaused"));

    paused = callReadOnly("is-contract-paused", []);
    expect(paused).toBeBool(false);

    result = callPublic("add-skill", [Cl.stringAscii("paused-skill")], userA);
    expect(result).toBeOk(Cl.stringAscii("Skill added"));

    result = callPublic("activate-emergency-mode", [], deployer);
    expect(result).toBeOk(Cl.stringAscii("Emergency mode activated"));

    let emergency = callReadOnly("is-emergency-mode-active", []);
    expect(emergency).toBeBool(true);

    result = callPublic("add-skill", [Cl.stringAscii("emergency-skill")], userA);
    expect(result).toBeErr(Cl.uint(503));

    result = callPublic("deactivate-emergency-mode", [], deployer);
    expect(result).toBeOk(Cl.stringAscii("Emergency mode deactivated"));

    emergency = callReadOnly("is-emergency-mode-active", []);
    expect(emergency).toBeBool(false);
  });
});

describe("ExperHive skills and reputation flows", () => {
  it("adds skills, records endorsements, and averages ratings", () => {
    let result = callPublic("add-skill", [Cl.stringAscii("solidity")], userA);
    expect(result).toBeOk(Cl.stringAscii("Skill added"));

    result = callPublic(
      "endorse",
      [Cl.standardPrincipal(userA), Cl.stringAscii("solidity")],
      userB,
    );
    expect(result).toBeOk(Cl.stringAscii("Endorsed"));

    result = callPublic(
      "set-endorser-weight",
      [Cl.standardPrincipal(userB), Cl.uint(5)],
      deployer,
    );
    expect(result).toBeOk(Cl.stringAscii("Weight set"));

    result = callPublic(
      "rate-skill",
      [Cl.standardPrincipal(userA), Cl.stringAscii("solidity"), Cl.uint(4)],
      userB,
    );
    expect(result).toBeOk(Cl.stringAscii("Rating added"));

    const rating = callReadOnly(
      "get-skill-rating",
      [Cl.standardPrincipal(userA), Cl.stringAscii("solidity")],
      userA,
    );
    expect(rating).toBeUint(4);
  });
});

describe("ExperHive challenge lifecycle", () => {
  it("creates a challenge, tracks participation, and accepts reviews", () => {
    const create = callPublic(
      "create-challenge",
      [
        Cl.stringAscii("challenge-skill"),
        Cl.stringAscii("Rust Challenge"),
        Cl.stringAscii("Ship a small Rust solution."),
        Cl.uint(3),
        Cl.uint(1000),
        Cl.uint(10),
        Cl.uint(5),
      ],
      userA,
    );
    const challengeId = cvToBigInt(unwrapOk(create));

    const details = callReadOnly("get-challenge-details", [Cl.uint(challengeId)], userA);
    expect(details).toHaveClarityType(ClarityType.OptionalSome);

    let result = callPublic(
      "participate-in-challenge",
      [Cl.uint(challengeId), Cl.stringAscii("submission-1")],
      userB,
    );
    expect(result).toBeOk(Cl.stringAscii("Participation recorded"));

    result = callPublic("add-authorized-verifier", [Cl.standardPrincipal(userC)], deployer);
    expect(result).toBeOk(Cl.stringAscii("Verifier added"));

    result = callPublic(
      "review-challenge-submission",
      [
        Cl.uint(challengeId),
        Cl.standardPrincipal(userB),
        Cl.uint(85),
        Cl.stringAscii("Solid submission."),
      ],
      userC,
    );
    expect(result).toBeOk(Cl.stringAscii("Review submitted"));

    const participation = callReadOnly(
      "get-challenge-participation",
      [Cl.uint(challengeId), Cl.standardPrincipal(userB)],
      userB,
    );
    expect(participation).toHaveClarityType(ClarityType.OptionalSome);
  });

  it("rejects completion when NFT minting targets the creator", () => {
    const create = callPublic(
      "create-challenge",
      [
        Cl.stringAscii("completion-skill"),
        Cl.stringAscii("Completion Test"),
        Cl.stringAscii("Check completion behavior."),
        Cl.uint(2),
        Cl.uint(1200),
        Cl.uint(8),
        Cl.uint(3),
      ],
      userA,
    );
    const challengeId = cvToBigInt(unwrapOk(create));

    const complete = callPublic("complete-challenge", [Cl.uint(challengeId)], userA);
    expect(complete).toBeErr(Cl.uint(508));
  });
});

describe("ExperHive multisig operations", () => {
  it("creates and approves a multisig operation", () => {
    const create = callPublic(
      "create-multisig-operation",
      [
        Cl.stringAscii("transfer-funds"),
        Cl.standardPrincipal(userB),
        Cl.uint(1000),
        Cl.uint(2),
      ],
      deployer,
    );
    const operationId = cvToBigInt(unwrapOk(create));

    const pending = callReadOnly("get-pending-operation", [Cl.uint(operationId)], deployer);
    expect(pending).toHaveClarityType(ClarityType.OptionalSome);

    const approve = callPublic("approve-multisig-operation", [Cl.uint(operationId)], userC);
    expect(approve).toBeOk(Cl.stringAscii("Operation approved"));

    const hasApproval = callReadOnly(
      "has-operation-approval",
      [Cl.uint(operationId), Cl.standardPrincipal(userC)],
      userC,
    );
    expect(hasApproval).toBeBool(true);
  });
});

describe("ExperHive NFT flow", () => {
  it("mints and transfers NFTs while keeping counts in sync", () => {
    const beforeOwner = cvToBigInt(
      callReadOnly("get-user-nfts", [Cl.standardPrincipal(userA)], userA),
    );
    const beforeRecipient = cvToBigInt(
      callReadOnly("get-user-nfts", [Cl.standardPrincipal(userB)], userB),
    );

    const mint = callPublic(
      "mint-skill-nft",
      [
        Cl.standardPrincipal(userA),
        Cl.stringAscii("nft-skill"),
        Cl.stringAscii("Expert"),
        Cl.stringAscii("skill-mastery"),
        Cl.stringAscii("https://example.com/nft/1"),
      ],
      userB,
    );
    const nftId = cvToBigInt(unwrapOk(mint));

    const details = callReadOnly("get-nft-details", [Cl.uint(nftId)], userA);
    expect(details).toHaveClarityType(ClarityType.OptionalSome);

    const afterMintOwner = cvToBigInt(
      callReadOnly("get-user-nfts", [Cl.standardPrincipal(userA)], userA),
    );
    expect(afterMintOwner).toBe(beforeOwner + 1n);

    const transfer = callPublic("transfer-nft", [Cl.uint(nftId), Cl.standardPrincipal(userB)], userA);
    expect(transfer).toBeOk(Cl.stringAscii("NFT transferred"));

    const afterTransferOwner = cvToBigInt(
      callReadOnly("get-user-nfts", [Cl.standardPrincipal(userA)], userA),
    );
    const afterTransferRecipient = cvToBigInt(
      callReadOnly("get-user-nfts", [Cl.standardPrincipal(userB)], userB),
    );

    expect(afterTransferOwner).toBe(beforeOwner);
    expect(afterTransferRecipient).toBe(beforeRecipient + 1n);
  });
});
