#!/bin/bash
readonly RES='\e[0m'
readonly RED='\e[0;31m'
readonly GRE='\e[0;32m'
readonly YEL='\e[0;33m'
readonly BRED='\e[1;31m'
readonly BGRE='\e[1;32m'
readonly BYEL='\e[1;33m'

mkdir -p /data/{conf,db,repo,input}
gpg-agent --daemon
if [ -f /data/conf/keypair.gpg ]; then
	echo -e "${BGRE}Found secret! Importing ...${RES}"
	# Import Private Key
	KEY=$(gpg --with-colons --show-key /data/conf/keypair.gpg | grep -m 1 '^sec' | cut -d':' -f5)
	/usr/lib/gnupg2/gpg-preset-passphrase --preset --passphrase "${PASS}" "$(gpg --with-colons --show-key /data/conf/keypair.gpg | grep -m 1 '^grp' | cut -d':' -f10)"
	gpg --batch --import /data/conf/keypair.gpg
else
	echo -e "${YEL}No secret found! Creating one ...${RES}"
	echo -e "${BRED}Importing your own secret is recommended. Place it in '/data/conf/secret.gpg'.${RES}"
	sed -e "s/__KEYTYPE__/${KEYTYPE}/g" \
	    -e "s/__KEYLENGTH__/${KEYLENGTH}/g" \
	    -e "s/__SUBKEYTYPE__/${KEYTYPE}/g" \
	    -e "s/__SUBKEYLENGTH__/${KEYLENGTH}/g" \
	    -e "s/__NAME__/${NAME}/g" \
	    -e "s/__EMAIL__/${EMAIL}/g" \
	    -e "s/__EXPIRE__/${EXPIRE}/g" \
	    /usr/share/aktin-reprepro/gen-key.template >./gen-key

	# Generate Keypair
	exec 3< <(echo "${PASS}")
	gpg --batch --pinentry-mode loopback --passphrase-fd 3 --gen-key gen-key
	KEY=$(gpg --with-colons --list-secret-keys | grep -m 1 '^sec' | cut -d':' -f5)
	/usr/lib/gnupg2/gpg-preset-passphrase --preset --passphrase "${PASS}" "$(gpg --with-colons --list-secret-keys | grep -m 1 '^grp' | cut -d':' -f10)"

	# Export Private Key
	exec 3< <(echo "${PASS}")
	gpg --batch --pinentry-mode loopback --passphrase-fd 3 --armor --export-secret-keys "${KEY}" >/data/conf/keypair.gpg

	# Export Public Key
	gpg --armor --export "${KEY}" >>/data/conf/keypair.gpg
fi

if [ ! -f /data/repo/aktin.gpg ]; then
	echo -e "${GRE}Exporting GPG public key to repository ...${RES}"
	gpg --armor --export "${KEY}" >/data/repo/aktin.gpg
fi

if [ "${VERIFY}" = "true" ] && [ ! -f /data/conf/trusted.gpg ]; then
	echo -e "${BRED}No trusted keyring found in '/data/conf/trusted.gpg'. Verification of .deb archives is not possible.${RES}"
elif [ -f /data/conf/trusted.gpg ]; then
	echo -e "${BGRE}Trusted keyring found. Importing ...${RES}"
	gpg --batch --import /data/conf/trusted.gpg
fi

if [ ! -f /data/conf/distributions ]; then
	echo -e "${YEL}distributions file not found! Creating ...${RES}"
	sed -e "s/__ORIGIN__/${ORIGIN}/g" \
	    -e "s/__LABEL__/${LABEL}/g" \
	    -e "s/__SUITE__/${SUITE}/g" \
	    -e "s/__RELEASE__/${RELEASE}/g" \
	    -e "s/__ARCHITECTURES__/${ARCHITECTURES}/g" \
	    -e "s/__COMPONENTS__/${COMPONENTS}/g" \
	    -e "s/__DESCRIPTION__/${DESCRIPTION}/g" \
	    -e "s/__KEY__/${KEY}/g" \
	    /usr/share/aktin-reprepro/distributions.template >/data/conf/distributions
fi
if [ ! -f /data/conf/options ]; then
	echo -e "${YEL}options file not found! Creating ...${RES}"
	sed -e "" /usr/share/aktin-reprepro/options.template >/data/conf/options
fi

FILES=$(find /data/input -type f -name '*.deb'; echo -n "EOF")
echo -e "${BGRE}Found $(echo -n "${FILES%EOF}" | wc -l) file(s). Processing ...${RES}"
echo -n "${FILES%EOF}" | while IFS= read -r file; do
	if [ "${VERIFY}" = "true" ] && ! dpkg-sig --verify "${file}"; then
		echo -e "${RED}Verification of ${file} failed! Skipping ...${RES}"
		continue
	fi
	reprepro -b /data includedeb "${RELEASE}" "${file}" && \
	rm -f "${file}" && \
	echo -e "${GRE}${file} processed!${RES}" || \
	echo -e "${RED}Inclusion of ${file} failed!${RES}"
done
echo -e "${BGRE}Finished!${RES}"

